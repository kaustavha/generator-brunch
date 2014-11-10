util = require 'util'
fs = require 'fs'
{spawn} = require 'child_process'
coffee = require 'coffee-script'
Q = require 'q'
coffee.register()
bu = require './src/buildUtils'

# NPM deps
nodeModules = [
    'brunch'
    'javascript-brunch'
    'css-brunch'
    'uglify-js-brunch'
    'clean-css-brunch'
    ]

# Create brunch dependencies list
transpilers = [
    'jade'
    'stylus'
    'coffee-script'
    'sass'
    'less'
    'stylus'
    'clojure-script'
]
transpilers.forEach (t) ->
    nodeModules.push t + '-brunch'

# Bower deps
UiFrameworks = [
    'foundation'
    'topcoat'
    'pure'
    'bootstrap'
]

task 'generate', 'Generate the yeoman generator using the generator generator', ->
    bu.fromCSON 'bower', 'src', 'app/templates', '_bower'
    .then ->
        bu.conditionalDependencyInjector UiFrameworks, 'bower'
    .then ->
        bu.dependencyInjector [
            'jquery'
            'modernizr'
            'json3'
            'es5-shim'
        ], 'bower'
    .then ->
        bu.fromCSON 'package', 'src', 'app/templates', '_package'
    .then ->
        bu.dependencyInjector nodeModules, 'npm', 'devDependencies'

    bu.copyAndTranspile 'base.coffee'
    bu.copyAndTranspile 'index.coffee'

    console.log 'Done with the sync stuff'
