using System.Diagnostics;
using Microsoft.AspNetCore.Http;
using PetHealthEcosystem.Api.Observability;

namespace PetHealthEcosystem.Api.Middleware
{
    public class MetricsMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly PetMetrics _metrics;

        public MetricsMiddleware(RequestDelegate next, PetMetrics metrics)
        {
            _next = next;
            _metrics = metrics;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var stopwatch = Stopwatch.StartNew();
            try
            {
                await _next(context);
            }
            finally
            {
                stopwatch.Stop();
                var isError = context.Response.StatusCode >= 400;
                _metrics.RecordRequest(stopwatch.Elapsed.TotalMilliseconds, isError);
            }
        }
    }
}
