util = require 'util'
yeoman = require 'yeoman-generator'


RouteGenerator = yeoman.generators.NamedBase.extend
  init: ->
    console.log'You called the route subgenerator with the argument ' + @name + '.'

  files: ->
    @copy 'somefile.js', 'somefile.js'
  


module.exports = RouteGenerator;