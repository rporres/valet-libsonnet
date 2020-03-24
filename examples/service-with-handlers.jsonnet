local slo = import '../valet.libsonnet';

// Rules that will be reused in SLO rules
local labels = ['service="foo"', 'component="bar"'];
local rates = ['5m'];
local httpRates = slo.httpRates({
  metric: 'haproxy_server_http_responses_total',
  selectors: ['route="bar-prod"'],
  rates: rates,
  labels: labels,
  handlers: ['job="read"', 'job="write"'],
});
local latencyPercentileRates = slo.latencyPercentileRates({
  metric: 'foo_upload_seconds_bucket',
  percentile: '95',
  selectors: ['selector="qux"'],
  labels: labels,
  rates: rates,
  handlers: ['job="read"', 'job="write"'],
});

// SLOs from above rules (they will inherit the labels)
local volumeSLO = slo.volumeSLO({
  rules: httpRates.rateRules,
  threshold: 100,
  selectors: ['route="bar-prod"', 'status_class!="5xx"'],
});
local latencySLO = slo.latencySLO({
  rules: latencyPercentileRates.rules,
  rulesBuilder: latencyPercentileRates.rulesBuilder,
  threshold: '0.1',
});
local errorsSLO = slo.errorsSLO({
  rules: httpRates.errorRateRules,
  rulesBuilder: httpRates.errorRateRulesBuilder,
  threshold: '0.001',
  selectors: ['route="bar-prod"'],
});
local availabilitySLO = slo.availabilitySLO(
  errorsSLO.rulesProductBuilder, latencySLO.rulesProductBuilder
);

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
