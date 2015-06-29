Handlebars = require 'handlebars'
_          = require 'lodash'

extract = (template, emit) ->

  helperDetails =
    each:
      context: 0
    with:
      context: 0

  parsed = Handlebars.parse(template)

  extend = (path, subpath) ->
    if subpath.original? and _.startsWith(subpath.original, '@root')
      clone = _.clone subpath.parts
      clone.slice 1
    else
      clone = _.clone path
      _.each subpath.parts, (level) ->
        clone.push(level)
      clone

  visit = (emit, path, node) ->
    switch node.type

      when 'Program'
        _.each node.body, (child) -> visit(emit, path, child)

      when 'BlockStatement'
        _.each node.params, (child) -> visit(emit, path, child)
        newPath = path
        if helperDetails[node.path.original]?.context?
          replace = (path) ->
            newPath = path
          visit replace, path, node.params[helperDetails[node.path.original].context]
        visit(emit, newPath, node.program)

      when 'PathExpression'
        emit extend(path, node)

      when 'MustacheStatement'
        visit(emit, path, node.path)

  visit(emit, [], parsed)
  return


module.exports =
  extract: extract