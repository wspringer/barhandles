const Handlebars = require("handlebars");
const _ = require("lodash");

const extract = function (template, callback, opts) {
    if (opts == null) {
        opts = {};
    }
    /**
     * Notifies the client of references found.
     */
    const emit = (segs, optional) => callback(_.flatten(segs), optional);

    /**
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
     *
     * The `optional` parameter indicates wether any further deeper references should be considered
     * optional or not.
     */
    const helperDetails = _.merge(
        {},
        {
            each: {
                contextParam: 0,
                transmogrify(path) {
                    const clone = path.slice(0);
                    clone.push("#");
                    return clone;
                }
            },
            with: {
                contextParam: 0
            },
            if: {
                optional: true
            }
        },
        opts
    );

    /**
     * The data structure of the parsed handlebars template.
     */
    const parsed = Handlebars.parse(template);

    /**
     * Extends the given path with a new subpath.
     *
     * @param  {Array} path     A path.
     * @param  {Object} subpath A subpath produce by the Handlebars parser.
     * @return {Array}          A new path, the original path with the subpath appended in a way
     *                          that makes sense.
     */
    const extend = function (path, subpath) {
        // Subpaths that start with @root require special treatment.
        let clone;
        if (subpath.original != null && _.startsWith(subpath.original, "@root")) {
            clone = _.clone(subpath.parts);
            return [clone.slice(1)];
            // Deal with parent references. Seems to be incomplete.
            // @todo Make this recursive

            // Ignoring @index and @key
        } else if (subpath.original != null && _.startsWith(subpath.original, "@")) {
        } else if (subpath.original != null && _.startsWith(subpath.original, "../")) {
            clone = _.last(path) === "#" ? path.slice(0, -2) : path.slice(0, -1);
            clone.push(subpath.parts);
            return clone;
            // Do what you'd normally do: simply append the parts.
        } else {
            clone = _.clone(path);
            clone.push(subpath.parts);
            return clone;
        }
    };

    var visit = function (emit, path, node, optional) {
        if (optional == null) {
            optional = false;
        }
        switch (node.type) {
            case "Program":
                _.each(node.body, (child) => visit(emit, path, child, optional));
                break;

            case "BlockStatement":
                var newPath = path;
                var helper = helperDetails[node.path.original];
                _.each(node.params, (child) =>
                    visit(emit, path, child, optional || (helper != null ? helper.optional : undefined))
                );
                if ((helper != null ? helper.contextParam : undefined) != null) {
                    const replace = (path) => (newPath = path);
                    visit(replace, path, node.params[helper.contextParam]);
                    if ((helper != null ? helper.transmogrify : undefined) != null) {
                        newPath =
                            helperDetails[node.path.original] != null
                                ? helperDetails[node.path.original].transmogrify(newPath)
                                : undefined;
                    }
                }
                visit(emit, newPath, node.program, optional || (helper != null ? helper.optional : undefined));
                break;

            case "PathExpression":
                emit(extend(path, node), optional);
                break;

            case "MustacheStatement":
                helper = helperDetails[node.path.original];
                if (_.isEmpty(node.params)) {
                    visit(emit, path, node.path, optional);
                } else {
                    _.each(node.params, (child) =>
                        visit(emit, path, child, optional || (helper != null ? helper.optional : undefined))
                    );
                }
                break;
        }
    };

    return visit(emit, [], parsed);
};

/**
 * Extract a schema based on our own limited schema language: a tree structure with for every node
 * the `_type` and potentially children.
 *
 * @param  {String} template The Handlebars template, as a String.
 * @return {Object}          Our own schema.
 */
const extractSchema = function (template, opts) {
    const obj = {};
    const callback = function (path, optional) {
        var augment = function (obj, path) {
            obj._optional = _.has(obj, "_optional") ? optional && obj._optional : optional;
            if (!(_.isEmpty(path) || (path.length === 1 && path[0] === "length"))) {
                obj._type = "object";
                const segment = _.head(path);
                if (segment === "#") {
                    obj._type = "array";
                }
                obj[segment] = obj[segment] || {};
                return augment(obj[segment], _.tail(path));
            } else {
                obj._type = "any";
                return obj;
            }
        };
        return augment(obj, path);
    };
    extract(template, callback, opts);
    delete obj._optional;
    return obj;
};

module.exports = {
    extract,

    extractSchema
};
