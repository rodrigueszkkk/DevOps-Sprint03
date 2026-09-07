using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using PetHealthEcosystem.Api.Application.Interfaces;
using PetHealthEcosystem.Api.Application.Services;
using PetHealthEcosystem.Api.Data;
using PetHealthEcosystem.Api.Domain.Interfaces;
using PetHealthEcosystem.Api.Infrastructure.Repositories;
using PetHealthEcosystem.Api.Middleware;
using PetHealthEcosystem.Api.Observability;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// =====================================================================
// 1. LOGGING ESTRUTURADO (Serilog) - console + arquivo, níveis e correlação
// =====================================================================
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] ({CorrelationId}) {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        path: "logs/log-.txt",
        rollingInterval: RollingInterval.Day,
        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss} {Level:u3}] ({CorrelationId}) {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

builder.Host.UseSerilog();

// =====================================================================
// 2. SERVIÇOS / INJEÇÃO DE DEPENDÊNCIA
// =====================================================================
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? builder.Configuration.GetConnectionString("OracleConnection")
    ?? "Server=localhost;Port=3306;Database=pethealth_db;User=pethealth_user;Password=pethealth_pass;";

// Em ambiente de teste (WebApplicationFactory) o DbContext é substituído por InMemory,
// então só registramos o provedor de banco fora do ambiente "Testing".
if (!builder.Environment.IsEnvironment("Testing"))
{
    if (connectionString.Contains("User Id=", StringComparison.OrdinalIgnoreCase) && !connectionString.Contains("Port=3306"))
    {
        builder.Services.AddDbContext<AppDbContext>(options => options.UseOracle(connectionString));
    }
    else
    {
        builder.Services.AddDbContext<AppDbContext>(options =>
            options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
    }
}

builder.Services.AddScoped<IPetRepository, PetRepository>();
builder.Services.AddScoped<IPetService, PetService>();
builder.Services.AddScoped<IMedicalRecordRepository, MedicalRecordRepository>();
builder.Services.AddScoped<IMedicalRecordService, MedicalRecordService>();

builder.Services.AddMetrics();
builder.Services.AddSingleton<PetMetrics>();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// =====================================================================
// 3. HEALTH CHECKS
//    - Conectividade com o Banco de Dados (MySQL ou Oracle)
//    - Disponibilidade de serviço externo
// =====================================================================
var healthChecksBuilder = builder.Services.AddHealthChecks();

if (!builder.Environment.IsEnvironment("Testing"))
{
    if (connectionString.Contains("User Id=", StringComparison.OrdinalIgnoreCase) && !connectionString.Contains("Port=3306"))
    {
        healthChecksBuilder.AddOracle(
            connectionString,
            name: "oracle-database",
            tags: new[] { "db", "oracle", "ready" });
    }
    else
    {
        healthChecksBuilder.AddMySql(
            connectionString,
            name: "mysql-database",
            tags: new[] { "db", "mysql", "ready" });
    }
}

healthChecksBuilder.AddUrlGroup(
    new Uri("https://api.github.com"),
    name: "external-service",
    tags: new[] { "external", "ready" });

// =====================================================================
// 4. OPENTELEMETRY - TRACING E MÉTRICAS
// =====================================================================
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource.AddService(serviceName: "PetHealthEcosystem.Api"))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddEntityFrameworkCoreInstrumentation()
        .AddConsoleExporter())
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddMeter(PetMetrics.MeterName)
        .AddConsoleExporter());

var app = builder.Build();

// =====================================================================
// 5. PIPELINE HTTP
// =====================================================================
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<MetricsMiddleware>();

app.UseSerilogRequestLogging();

// Swagger habilitado para testes locais e em nuvem (ACI)
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "PetHealth Ecosystem API v1");
    c.RoutePrefix = "swagger";
});

app.UseAuthorization();
app.MapControllers();

// Endpoints de Health Check
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false, // apenas confirma que o processo está de pé
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

try
{
    Log.Information("Iniciando PetHealthEcosystem.Api");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "A aplicação falhou ao iniciar");
    throw;
}
finally
{
    Log.CloseAndFlush();
}

// Classe parcial necessária para que o WebApplicationFactory<Program>
// dos testes de integração enxergue o entrypoint da API.
public partial class Program { }
