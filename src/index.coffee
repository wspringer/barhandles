Handlebars = require 'handlebars'
_          = require 'lodash'

extract = (template, callback) ->

  emit = (segs) ->
    callback(_.flatten(segs))

  helperDetails =
    each:
      contextParam: 0
      transmogrify: (path) ->
        clone = path.slice 0
        clone.push('#')
        clone
    with:
      contextParam: 0

  parsed = Handlebars.parse(template)

  extend = (path, subpath) ->
    if subpath.original? and _.startsWith(subpath.original, '@root')
      clone = _.clone subpath.parts
      [clone.slice(1)]
    else if subpath.original? and _.startsWith(subpath.original, '../')
      clone = path.slice(0, -1)
      clone.push subpath.parts
      clone
    else
      clone = _.clone path
      clone.push subpath.parts
      clone

  visit = (emit, path, node) ->
    switch node.type

      when 'Program'
        _.each node.body, (child) -> visit(emit, path, child)

      when 'BlockStatement'
        _.each node.params, (child) -> visit(emit, path, child)
        newPath = path
        if helperDetails[node.path.original]?.contextParam?
          replace = (path) ->
            newPath = path
          visit replace, path, node.params[helperDetails[node.path.original].contextParam]
          if helperDetails[node.path.original]?.transmogrify?
            newPath = helperDetails[node.path.original]?.transmogrify(newPath)
        visit(emit, newPath, node.program)

      when 'PathExpression'
        emit extend(path, node)

      when 'MustacheStatement'
        visit(emit, path, node.path)

    return

  visit(emit, [], parsed)


module.exports =
  extract: extract