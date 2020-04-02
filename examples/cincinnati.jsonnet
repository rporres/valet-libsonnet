local slo = import '../valet.libsonnet';

// Rules that will be reused in SLO rules
local labels = ['service="cincinnati"', 'component="cincinnati-policy-engine"'];
local httpRates = slo.httpRates({
  metric: 'haproxy_server_http_responses_total',
  selectors: ['route="cincinnati-route-prod"'],
  labels: labels,
});
local latencyPercentileRates = slo.latencyPercentileRates({
  metric: 'cincinnati_pe_v1_graph_serve_duration_seconds_bucket',
  percentile: '90',
  selectors: ['job="cincinnati-policy-engine"'],
  labels: labels,
});

// SLOs from above rules (they will inherit the labels)
local volumeSLO = slo.volumeSLO({
  rules: httpRates.rateRules,
  threshold: '5000',
});
local latencySLO = slo.latencySLO({
  rules: latencyPercentileRates.rules,
  threshold: '3',
});
local errorsSLO = slo.errorsSLO({
  rules: httpRates.errorRateRules,
  threshold: '1',
});
local availabilitySLO = slo.availabilitySLO({
  latencyRules: [latencySLO.rules],
  errorsRules: [errorsSLO.rules],
});

{
  recordingrule:
    httpRates.rateRules +
    httpRates.errorRateRules +
    latencyPercentileRates.rules +
    volumeSLO.rules +
    latencySLO.rules +
    errorsSLO.rules +
    availabilitySLO.rules,
}
