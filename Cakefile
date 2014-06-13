coffee = require 'coffee-script'
util = require 'util'
fs = require 'fs'
coffee.register()
BrunchBase = require './src/base'
rewriter = require './src/rewriter'

class GeneratorGenerator
    {spawn} = require 'child_process'
    bowerPkgs = [
        'foundation'
        'topcoat'
        'pure'
        'bootstrap'
        'modernizr'
        'jquery'
        'json3'
        'es5-shim'
    ]

    nodePkgs = [
        'brunch'
        'coffee-script-brunch'
        'jade-brunch'
        'less-brunch'
        'stylus-brunch'
        'javascript-brunch'
        'css-brunch'
        'uglify-js-brunch'
        'clean-css-brunch'
    ]

    getVersion: (dep) ->
        versionData = spawn 'npm', ['info', dep, '--json']
        versionData.stdout.on 'data', (data) ->
            data = JSON.parse(data)
            l = data.versions.length - 1
            v = data.versions[l]

    pkgBldr: ->
            packages = [bowerPkgs, nodePkgs]
            packages.forEach (pkg, i) ->
                if i is 0
                    cmd = 'bower'
                    name = '_bower.json'
                else if i is 1
                    cmd = 'npm'
                    name = '_package.json'
                args = {}
                args.file = './app/templates/'
                args.file += name
                args.needle = '"dependencies":'
                args.replace = 'a'
                @args = args
                pkg.forEach (dependency) ->
                    v = 0
                    l = 0
                    versionData = spawn cmd, ['info', dependency, '--json']
                    versionData.stdout.on 'data', (data) =>
                        data = JSON.parse(data)
                        l = data.versions.length - 1
                        @v = data.versions[l]
                    if not args.splicable then args.splicable = []
                    args.splicable.push '<% if (' + dependency + ') { %>'
                    args.splicable.push '"' + dependency + '": "' + v + '",'
                    args.splicable.push '<% } %>'
                    @args.splicable = args.splicable
                rewriter @args

    copyAndTranspile: (fileName) ->
        spawn 'coffee', ['-c', '-b', '-w', '-o', './app', fileName]


task 'generate', 'Generate the yeoman generator using the generator generator', ->
    GG = new GeneratorGenerator()
    GG.pkgBldr()
    GG.copyAndTranspile 'base.coffee'
    GG.copyAndTranspile 'index.coffee'
