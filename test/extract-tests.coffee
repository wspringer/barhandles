chai        = require 'chai'
sinon       = require 'sinon'
sinonChai   = require 'sinon-chai'

chai.use(sinonChai)
expect = chai.expect

{ extract, extractSchema } = require '../src/index'


describe 'extract', ->

  emit = null

  beforeEach ->
    emit = sinon.stub()

  it 'should allow you to extract simple references', ->
    extract '{{foo.bar}}', emit
    expect(emit).to.be.calledWith ['foo', 'bar']

  it "should support 'each'", ->
    extract '{{#each foo}}{{bar}}{{/each}}', emit
    expect(emit).to.be.calledWith ['foo', '#', 'bar']

  it "should support 'each' without getting hung up on @index", ->
    extract """
{{#each foo}}{{@index}}{{/each}}
"""
      , emit
    expect(emit).not.to.be.calledWith ['foo', '#', 'index']


  it "should support 'with'", ->
    extract '{{#with foo}}{{bar}}{{/with}}', emit
    expect(emit).to.be.calledWith ['foo', 'bar']

  it "should support '@root'", ->
    extract '{{#each foo.bar}}{{@root.bar}}{{/each}}', emit
    expect(emit).to.be.calledWith ['bar']

  it "should support '../'", ->
    extract '{{#with foo}}{{#each bar}}{{../baz}}{{/each}}{{/with}}', emit
    expect(emit).to.be.calledWith ['foo', 'baz']

  it 'should be able to deal with simple extensions', ->
    extract '{{alt foo.bar foo.baz}}', emit
    expect(emit).to.be.calledWith ['foo','bar']
    expect(emit).to.be.calledWith ['foo','baz']

  it "should support generating a schema", ->
    expect(extractSchema).to.be.defined
    expect(extractSchema).to.be.a 'function'
    template = """
{{#each foo}}
  {{bar}}
  {{@root.baz}}
  {{../baz}}
{{/each}}
"""
    schema = extractSchema(template)
    expect(schema).to.have.property 'foo'
    expect(schema.foo).to.have.property '_type', 'array'
    expect(schema).to.have.property 'baz'
    expect(schema.baz).to.have.property '_type', 'any'
    expect(schema.foo).to.have.property '#'
    expect(schema.foo['#']).to.have.property 'bar'
    expect(schema.foo['#'].bar).to.have.property '_type', 'any'

  it 'should handle simple helpers correctly', ->
    extract '{{currency amount}}', emit
    expect(emit).to.be.calledWith ['amount']

  it 'should deal with ifs in a meaningful way', ->
    extract '{{#if foo}}{{foo.bar}}{{/if}}', emit
    expect(emit).to.be.calledWith ['foo'], true
    expect(emit).to.be.calledWith ['foo', 'bar'], true

  it 'should deal with optionals correctly while generating a schema', ->
    template = """
{{foo.baz}}
{{#if foo}}
{{@root.go}}
{{foo.bar.yoyo}}
{{/if}}
"""
    schema = extractSchema(template)
    expect(schema).to.have.property 'foo'
    expect(schema.foo).to.have.property '_optional', false
    expect(schema.foo).to.have.property 'bar'
    expect(schema.foo.bar).to.have.property '_optional', true

  it 'should allow you to add definitions for other directives', ->
    template = """
{{alt foo.bar foo.baz}}
"""
    extract template, emit,
      alt:
        optional: true
    expect(emit).to.be.calledWith ['foo','bar'], true

  it 'should consider all parts of a ternary operator to be optional', ->
    template = """
{{ternary foo.bar foo.baz foo.gum}}
"""
    schema = extractSchema template,
      ternary:
        optional: true
    expect(schema).to.have.deep.property 'foo.bar._optional', true
    expect(schema).to.have.deep.property 'foo.baz._optional', true
    expect(schema).to.have.deep.property 'foo.gum._optional', true

  it 'should ignore variables starting with @', ->
    template = """
{{@foo.bar}}
"""
    schema = extractSchema template
    expect(schema).to.not.have.property 'foo'

  it 'should not consider something with length property to be an object', ->
    template = """
{{foo.length}}
"""
    schema = extractSchema template
    expect(schema).to.have.property 'foo'
    expect(schema.foo).to.have.property '_type', 'any'


