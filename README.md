# README

A proof of concept to check how hard it would be to extract variable references from Handlebars templates.

```javascript
barhandles = require('barhandles');

barhandles.extract('{{foo.bar}}', callback);
// Callback will be invoked with ['foo', 'bar']

barhandles.extract('{{#with foo}}{{bar}}{{/with}}', callback);
// Callback will be invoked with ['foo', 'bar']

barhandles.extract('{{#each foo}}{{bar}}{{/each}}', callback);
// Callback will be invoked with ['foo', '#', 'bar']

```

