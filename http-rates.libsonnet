local util = import '_util.libsonnet';
{
  httpRates(param):: {
    local slo = {
      metric: error 'must set metric for errorburn',
      selectors: error 'must set selectors for errorburn',
      labels: [],
      rates: ['5m', '30m', '1h', '2h', '6h', '1d'],
      codeSelector: 'code',
    } + param,

    local labels =
      util.selectorsToLabels(slo.selectors) +
      util.selectorsToLabels(slo.labels),

    rateRules: [
      {
        expr: |||
          sum by (status_class) (
            label_replace(
              rate(%s{%s}[%s]
            ), "status_class", "${1}xx", "%s", "([0-9])..")
          )
        ||| % [
          slo.metric,
          std.join(',', slo.selectors),
          rate,
          slo.codeSelector,
        ],
        record: 'status_class:http_responses_total:rate%s' % rate,
        labels: labels,
        rate:: rate,
      }
      for rate in std.uniq(slo.rates)
    ],

    errorRateRules: [
      {
        expr: |||
          sum(%s{%s})
          /
          sum(%s{%s})
        ||| % [
          r.record,
          std.join(',', slo.selectors + ['status_class="5xx"']),
          r.record,
          std.join(',', slo.selectors),
        ],
        record: 'status_class_5xx:http_responses_total:ratio_rate%s' % r.rate,
        labels: labels,
        rate:: r.rate,
        handlers:: slo.handlers,
      }
      for r in self.rateRules
    ],
  },
}
