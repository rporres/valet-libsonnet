local recordName(category, rate) =
  'component:%s:slo_ok_%s' % [category, rate];

local sloFromRecordingRules(category, param) =
  local slo = {
    rules: error 'must set rules for %sSLO' % category,
    threshold: error 'must set a threshold for %s SLO' % category,
    selectors: [],
  } + param;

  local exprString =
    if std.length(slo.selectors) == 0
    then '%s < bool(%s)'
    else '%s{%s} < bool(%s)';

  [
    {
      record: recordName(category, r.rate),
      expr: exprString %
            if std.length(slo.selectors) == 0
            then [r.record, slo.threshold]
            else [r.record, std.join(',', slo.selectors), slo.threshold],
      labels: r.labels,
      rate:: r.rate,
    }
    for r in slo.rules
  ];

local rulesProductBuilder(category, rulesBuilder) =
  [
    {
      record: recordName(category, r.rate),
      handlers: r.handlers,
      labels: r.labels,
      rate: r.rate,
    }
    for r in rulesBuilder
  ];

local SLOProductRules(SLORulesProductBuilder) =
  [
    if std.length(rule.handlers) == 0
    then rule
    else {
      record: std.join(' * ', std.map(function(handler) '%s{%s}' % [
        rule.record,
        handler,
      ], rule.handlers)),
    }
    for rule in SLORulesProductBuilder
  ];

{
  volumeSLO(param):: {
    rules: sloFromRecordingRules('volume', param),
  },

  latencySLO(param):: {
    rules: sloFromRecordingRules('latency', param),
    rulesProductBuilder: rulesProductBuilder('latency', param.rulesBuilder),
  },

  errorsSLO(param):: {
    rules: sloFromRecordingRules('errors', param),
    rulesProductBuilder: rulesProductBuilder('errors', param.rulesBuilder),
  },

  availabilitySLO(errorsSLORulesProductBuilder, latencySLORulesProductBuilder):: {
    local errorsLength = std.length(errorsSLORulesProductBuilder),
    local latencyLength = std.length(latencySLORulesProductBuilder),
    assert latencyLength == errorsLength :
           error 'Non-matching length for input arrays. %d != %d' % [latencyLength, errorsLength],

    local latencySLOProductRules = SLOProductRules(latencySLORulesProductBuilder),
    local errorsSLOProductRules = SLOProductRules(errorsSLORulesProductBuilder),

    rules: [
      {
        record: 'component:availability:slo_ok_%s' % errorsSLORulesProductBuilder[i].rate,
        expr: '%s * %s' % [latencySLOProductRules[i].record, errorsSLOProductRules[i].record],
        labels: errorsSLORulesProductBuilder[i].labels + latencySLORulesProductBuilder[i].labels,
      }
      for i in std.range(0, latencyLength - 1)

    ],
  },
}
