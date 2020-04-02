{
  selectorsToLabels(selectorArray):: {
    [s[0]]: std.strReplace(s[1], '"', '')
    for s in [
      std.split(s, '=')
      for s in selectorArray
    ]
  },

  labelsToSelectorsString(labelsObject)::
    std.join(
      ',',
      std.map(
        function(key) "%s='%s'" % [key, labelsObject[key]],
        std.objectFields(labelsObject)
      )
    ),
}
