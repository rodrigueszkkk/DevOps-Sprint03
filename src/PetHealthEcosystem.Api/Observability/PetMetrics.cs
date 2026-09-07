using System.Diagnostics.Metrics;

namespace PetHealthEcosystem.Api.Observability
{
    public class PetMetrics
    {
        public const string MeterName = "PetHealthEcosystem.Api";

        private readonly Counter<long> _requestsTotal;
        private readonly Counter<long> _errorsTotal;
        private readonly Histogram<double> _requestDuration;

        public PetMetrics(IMeterFactory meterFactory)
        {
            var meter = meterFactory.Create(MeterName);

            _requestsTotal = meter.CreateCounter<long>(
                "pets_api.requests.total",
                description: "Total de requisições recebidas pela API.");

            _errorsTotal = meter.CreateCounter<long>(
                "pets_api.requests.errors",
                description: "Total de requisições que resultaram em erro (status >= 400).");

            _requestDuration = meter.CreateHistogram<double>(
                "pets_api.requests.duration",
                unit: "ms",
                description: "Tempo de resposta das requisições, em milissegundos.");
        }

        public void RecordRequest(double durationMs, bool isError)
        {
            _requestsTotal.Add(1);
            _requestDuration.Record(durationMs);
            if (isError) _errorsTotal.Add(1);
        }
    }
}
