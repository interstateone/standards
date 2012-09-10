define
  sentenceCase: (string) ->
    string.charAt(0).toUpperCase() + string.slice(1).toLowerCase()

  titleCase: (string) ->
    (word.charAt(0).toUpperCase() + word.slice(1).toLowerCase() for word in string.split ' ').join ' '

  pluralize: (word, count) -> if count > 1 then word += 's' else word

  gsub: (source, pattern, replacement) ->
    result = ''

    if _.isString pattern then pattern = RegExp.escape pattern

    unless pattern.length || pattern.source
      replacement = replacement ''
      replacement + source.split('').join(replacement) + replacement

    while source.length > 0
      if match = source.match pattern
        result += source.slice 0, match.index
        result += replacement match
        source = source.slice(match.index + match[0].length)
      else
        result += source
        source = ''
    return result
