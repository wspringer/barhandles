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
      clone =
        if _.last(path) is '#'
          path.slice(0, -2)
        else
          path.slice(0, -1)
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
        helper = helperDetails[node.path.original]
        if helper?.contextParam?
          replace = (path) ->
            newPath = path
          visit replace, path, node.params[helper.contextParam]
          if helper?.transmogrify?
            newPath = helperDetails[node.path.original]?.transmogrify(newPath)
        visit(emit, newPath, node.program)

      when 'PathExpression'
        emit extend(path, node)

      when 'MustacheStatement'
        if _.isEmpty(node.params)
          visit(emit, path, node.path)
        else
          _.each node.params, (child) ->
            visit(emit, path, child)

    return

  visit(emit, [], parsed)

extractSchema = (template) ->
  obj = {}
  callback = (path) ->
    augment = (obj, path) ->
      if not(_.isEmpty(path))
        obj._type = 'object'
        segment = _.head(path)
        if segment is '#' then obj._type = 'array'
        obj[segment] = obj[segment] or {}
        augment(obj[segment], _.tail(path))
      else
        obj._type = 'any'
        obj
    augment(obj, path)
  extract(template, callback)
  obj


module.exports =

  extract: extract

  extractSchema: extractSchema

