using Microsoft.AspNetCore.Http;
using Serilog.Context;

namespace PetHealthEcosystem.Api.Middleware
{
    /// <summary>
    /// Garante que toda requisição tenha um Correlation Id, propagado no header
    /// de resposta e injetado no contexto de log do Serilog, permitindo
    /// correlacionar todas as linhas de log de uma mesma requisição.
    /// </summary>
    public class CorrelationIdMiddleware
    {
        private const string HeaderName = "X-Correlation-Id";
        private readonly RequestDelegate _next;

        public CorrelationIdMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var correlationId = context.Request.Headers.TryGetValue(HeaderName, out var value) && !string.IsNullOrWhiteSpace(value)
                ? value.ToString()
                : Guid.NewGuid().ToString();

            context.Response.OnStarting(() =>
            {
                context.Response.Headers[HeaderName] = correlationId;
                return Task.CompletedTask;
            });

            using (LogContext.PushProperty("CorrelationId", correlationId))
            {
                await _next(context);
            }
        }
    }
}
