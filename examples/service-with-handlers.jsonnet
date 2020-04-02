local slo = import '../valet.libsonnet';

// Rules that will be reused in SLO rules
local labels = ['service="service"', 'component="component"'];
local rates = ['5m'];
local httpRatesRead = slo.httpRates({
  metric: 'http_responses_total',
  selectors: ['handler="read"'],
  rates: rates,
  labels: labels,
});
local httpRatesWrite = slo.httpRates({
  metric: 'http_responses_total',
  selectors: ['handler="write"'],
  rates: rates,
  labels: labels,
});

local latencyPercentileRatesRead = slo.latencyPercentileRates({
  metric: 'foo_upload_seconds_bucket',
  selectors: ['handler="read"'],
  percentile: '95',
  labels: labels,
  rates: rates,
});
local latencyPercentileRatesWrite = slo.latencyPercentileRates({
  metric: 'foo_upload_seconds_bucket',
  selectors: ['handler="write"'],
  percentile: '95',
  labels: labels,
  rates: rates,
});

local volumeSLORead = slo.volumeSLO({
  rules: httpRatesRead.rateRules,
  threshold: 100,
});
local volumeSLOWrite = slo.volumeSLO({
  rules: httpRatesWrite.rateRules,
  threshold: 200,
});
local latencySLORead = slo.latencySLO({
  rules: latencyPercentileRatesRead.rules,
  threshold: '0.1',
});
local latencySLOWrite = slo.latencySLO({
  rules: latencyPercentileRatesWrite.rules,
  threshold: '0.2',
});
local errorsSLORead = slo.errorsSLO({
  rules: httpRatesRead.errorRateRules,
  threshold: '0.001',
});
local errorsSLOWrite = slo.errorsSLO({
  rules: httpRatesWrite.errorRateRules,
  threshold: '0.001',
});

local availabilitySLORead = slo.availabilitySLO({
  latencyRules: [latencySLORead.rules],
  errorsRules: [errorsSLORead.rules],
});
local availabilitySLOWrite = slo.availabilitySLO({
  latencyRules: [latencySLOWrite.rules],
  errorsRules: [errorsSLOWrite.rules],
});

// We don't support for the moment availaility SLO as a product
// of other availability SLOs, but this is easy to overcome
local availabilitySLO = slo.availabilitySLO({
  latencyRules: [latencySLORead.rules] + [latencySLOWrite.rules],
  errorsRules: [errorsSLORead.rules] + [errorsSLOWrite.rules],
  // let's add one label that differentiate this from the rest as
  // handler selectors won't get in the selectors. We could also
  // do it querying through handler="" although I guess this is
  // clearer
  labels: ['handler="all"'],
});

{
  recordingrule:
    httpRatesRead.rateRules +
    httpRatesWrite.rateRules +
    httpRatesRead.errorRateRules +
    httpRatesWrite.errorRateRules +
    latencyPercentileRatesRead.rules +
    latencyPercentileRatesWrite.rules +
    volumeSLORead.rules +
    volumeSLOWrite.rules +
    latencySLORead.rules +
    latencySLOWrite.rules +
    errorsSLORead.rules +
    errorsSLOWrite.rules +
    availabilitySLORead.rules +
    availabilitySLOWrite.rules +
    availabilitySLO.rules,
}
