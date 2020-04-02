// TODO: We should revisit the whole idea of passing arrays of rules
// as arguments to build SLOs. It works fine with simple SLOs but
// it's a nightmare when dealing with availability SLOs. It may
// make more sense to pass rules objects with properties as
// rates, recordFormat, percentile that can help us build the SLO
// rules in a cleverer fashion
local util = import '_util.libsonnet';

local recordName(category, rate) =
  'component:%s:slo_ok_%s' % [category, rate];

local sloFromRecordingRules(category, param) =
  local slo = {
    rules: error 'must set rules for %sSLO' % category,
    threshold: error 'must set a threshold for %s SLO' % category,
    labels: [],
  } + param;

  [
    {
      record: recordName(category, r.rate),
      expr: '%s{%s} < bool(%s)' % [
        r.record,
        util.labelsToSelectorsString(r.labels),
        slo.threshold,
      ],
      labels: r.labels + util.selectorsToLabels(slo.labels),
      rate:: r.rate,
    }
    for r in slo.rules
  ];

// find all the labels that are common across the rules
// and remove those that have different values.
// rules is an array of arrays.
// There is an assumption of rules coming from our own
// rules generation and have similar structure.
// This is not pretty.
local commonLabels(rules) =
  local labelNames = std.set(
    std.flattenArrays(
      std.map(function(outer) std.objectFields(rules[outer][0].labels),
              std.range(0, std.length(rules) - 1))
    )
  );

  {
    [label]: rules[0][0].labels[label]
    for label in labelNames
    if std.length(std.set(
      std.map(
        function(outer) rules[outer][0].labels[label],
        std.range(0, std.length(rules) - 1)
      )
    )) == 1
  };


{
  volumeSLO(param):: {
    rules: sloFromRecordingRules('volume', param),
  },

  latencySLO(param):: {
    rules: sloFromRecordingRules('latency', param),
  },

  errorsSLO(param):: {
    rules: sloFromRecordingRules('errors', param),
  },

  // latencyRules and errorsRules are arrays of arrays of rules
  // In order to avoid getting this more complicated thatn it
  // already is, we don't support availability SLOs defined as
  // a product of other availability SLOs. Since we only support
  // availabilities that are product of latencies and errors, it
  // is not a problem but we may want to revisit this in the future.

  availabilitySLO(param):: {
    local slo = {
      latencyRules: error 'must set latencyRules for availabilitySLO',
      errorsRules: error 'must set errorsRules for availabilitySLO',
      labels: [],
    } + param,

    // TODO: Check inside arrays in rules have the same length

    // We will assume that all elements of each rule arrays have
    // the same structure and labels

    // Since the record name is common for every availability slo,
    // we need to find all the labels that are common across the rules
    // and remove those that have different values.
    local latencyLabels = commonLabels(slo.latencyRules),
    local errorsLabels = commonLabels(slo.errorsRules),

    // we need now to keep the labels that have the same value in both
    // objects or that doesn't exist in one or the other
    local sumLabels = latencyLabels + errorsLabels,
    local labels = {
      [key]: sumLabels[key]
      for key in std.objectFields(sumLabels)
      if std.objectHas(latencyLabels, key) && !std.objectHas(errorsLabels, key) ||
         !std.objectHas(latencyLabels, key) && std.objectHas(errorsLabels, key) ||
         latencyLabels[key] == errorsLabels[key]
    },

    local allRules = slo.latencyRules + slo.errorsRules,

    rules: [
      {
        record: recordName('availability', allRules[0][inner].rate),
        labels: labels + util.selectorsToLabels(slo.labels),
        expr: std.join(
          ' * ',
          std.map(
            function(outer) '%s{%s}' % [
              allRules[outer][inner].record,
              util.labelsToSelectorsString(allRules[outer][inner].labels),
            ],
            std.range(0, std.length(allRules) - 1)
          )
        ),
      }
      for inner in std.range(0, std.length(allRules[0]) - 1)
    ],
  },
}
