util = require 'util'
fs = require 'fs'
{spawn} = require 'child_process'
coffee = require 'coffee-script'
coffee.register()
bu = require('./src/buildUtils').Utilities

task 'generate', 'Generate the yeoman generator using the generator generator', ->
    bu.injectDeps [
        'brunch'
        'javascript-brunch'
        'css-brunch'
        'uglify-js-brunch'
        'clean-css-brunch'
        ], 'npm'

    transpilers = [
        'jade'
        'stylus'
        'coffee-script'
        'sass'
        'less'
    ]
    transpilers.forEach (t) ->
        bu.injectDeps t + '-brunch', 'npm', t
    
    bu.injectDeps [
        'jquery'
        'modernizr'
        'json3'
        'es5-shim'
        ], 'bower'
    
    UiFrameworks = [
        'foundation'
        'topcoat'
        'pure'
        'bootstrap'
    ]
    UiFrameworks.forEach (dep) ->
        bu.bowerInjector dep

    bu.copyAndTranspile 'base.coffee'
    bu.copyAndTranspile 'index.coffee'

    console.log 'Done with the sync stuff'
