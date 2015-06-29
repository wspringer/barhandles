chai        = require 'chai'
sinon       = require 'sinon'
sinonChai   = require 'sinon-chai'

chai.use(sinonChai)
expect = chai.expect

{ extract } = require '../src/index'


describe 'extract', ->

  emit = null

  beforeEach ->
    emit = sinon.stub()

  it 'should allow you to extract simple references', ->
    extract '{{foo.bar}}', emit
    expect(emit).to.be.calledWith ['foo', 'bar']

  it "should support 'each'", ->
    extract '{{#each foo}}{{bar}}{{/each}}', emit
    expect(emit).to.be.calledWith ['foo', 'bar']

  it "should support 'with'", ->
    extract '{{#with foo}}{{bar}}{{/with}}', emit
    expect(emit).to.be.calledWith ['foo', 'bar']