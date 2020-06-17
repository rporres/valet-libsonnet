{
  local hasSubStr(pat, s) = std.findSubstr(pat, s) != [],

  selectorsToLabels(selectorArray):: {
    [s[0]]: std.strReplace(s[1], '"', '')
    for s in [
      std.split(s, '=')
      for s in selectorArray
      if !hasSubStr('!=', s) && !hasSubStr('!~', s) && !hasSubStr('=~', s)
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
