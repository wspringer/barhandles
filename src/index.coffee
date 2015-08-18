Handlebars = require 'handlebars'
_          = require 'lodash'

extract = (template, callback) ->

  ###*
   * Notifies the client of references found.
  ###
  emit = (segs) ->
    callback(_.flatten(segs))

  ###*
   * The definition of how to handle different types of directives. 
   *
   * For each directive that requires special treatment, it has a key (the name of the directive).
   *
   * The contextParam indicates which parameter of the directive defines the context for any further
   * references. For the `each` directive, it is the first parameter, so the value of `contextParam`
   * is `0`:
   *
   * <pre><code>
   * {{#each foo.bar}} {{baz}} {{/each}}
   * </pre></code>
   *
   * The `transmogrify` function is taking the paths found in the directive and adjusting them
   * in whatever way you deem appropriate.
  ###
  helperDetails =
    each:
      contextParam: 0
      transmogrify: (path) ->
        clone = path.slice 0
        clone.push('#')
        clone
    with:
      contextParam: 0

  ###*
   * The data structure of the parsed handlebars template.
  ###
  parsed = Handlebars.parse(template)

  ###*
   * Extends the given path with a new subpath. 
   * 
   * @param  {Array} path     A path.
   * @param  {Object} subpath A subpath produce by the Handlebars parser.
   * @return {Array}          A new path, the original path with the subpath appended in a way 
   *                          that makes sense.
  ###
  extend = (path, subpath) ->
    # Subpaths that start with @root require special treatment.
    if subpath.original? and _.startsWith(subpath.original, '@root')
      clone = _.clone subpath.parts
      [clone.slice(1)]
    # Deal with parent references. Seems to be incomplete. 
    # @todo Make this recursive      
    else if subpath.original? and _.startsWith(subpath.original, '../')
      clone =
        if _.last(path) is '#'
          path.slice(0, -2)
        else
          path.slice(0, -1)
      clone.push subpath.parts
      clone
    # Do what you'd normally do: simply append the parts.      
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

###*
 * Extract a schema based on our own limited schema language: a tree structure with for every node
 * the `_type` and potentially children.
 * 
 * @param  {String} template The Handlebars template, as a String.
 * @return {Object}          Our own schema.
###
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

