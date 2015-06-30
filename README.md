# README

A proof of concept to check how hard it would be to extract variable references from Handlebars templates.

### One Minute Overview

```javascript
barhandles = require('barhandles');

barhandles.extract('{{foo.bar}}', callback);
// Callback will be invoked with ['foo', 'bar']

barhandles.extract('{{#with foo}}{{bar}}{{/with}}', callback);
// Callback will be invoked with ['foo', 'bar']

barhandles.extract('{{#each foo}}{{bar}}{{/each}}', callback);
// Callback will be invoked with ['foo', '#', 'bar']

barhandles.extract('{{#with foo}}{{#each bar}}{{../baz}}{{/each}}{{/with}}', callback);
// Callback will be invoked with ['foo','baz']

```

Barhandles also allows you to generate a hierarchical schema from your object model. 

```javascript
barhandlers.extractSchema('{{foo.bar}}');
```

will produce:

```json
{
  "foo": {
    "_type": "object",
    "bar": {
      "_type": "any"
    }
  }
}  
```  

### Change log

* `v0.3.0`: Support for extracting a schema. 
* `v0.2.0`: Initial version

