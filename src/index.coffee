# Node requires
path = require "path"
yosay = require "yosay"

# Base utilities class
BrunchBase = require './base.js'

class BrunchGenerator extends BrunchBase
    init: ->
        @pkg = require("../package.json")
        @on "end", ->
            @installDependencies() unless @options["skip-install"]

    askForInfo: ->
        # Have Yeoman greet the user.
        @log yosay("Welcome to the marvelous Brunch generator!")
        prompts = [
            name: 'appName'
            message: 'Pick a name for your app.'
            default: @_appNameFromDir
            validate: (ans) ->
                if !/^[a-zA-Z0-9]+$/.test(ans)
                    'The application name should only consist of the following characters a-z, A-Z and 0-9.'
                else true
        ,
            name: 'appDescr'
            message: 'Add a description for you app'
        ,
            name:'ghUser'
            message: 'Github username?'
            default: 'someuser'
        ]
        @_ask prompts, =>
            if @ghUser is 'someuser' 
                @github = false
            else
                @_githubUserInfo @ghUser, (res) =>
                    @realname = res.name
                    @email = res.email
                    @githubUrl = res.html_url

    askForLanguages: ->
        @_ask [
            type: 'checkbox'
            name: 'tools'
            message: 'Pick any of the following transpilers'
            choices: [
                name: 'CoffeeScript'
                value: 'coffee-script'
                checked: true
            ,
                name: 'Stylus'
                value: 'stylus'
                checked: true
            ,
                name: 'Jade'
                value: 'jade'
                checked: true
            ]
        ]

    askForUIFramework: ->
        @_ask [
            type: 'checkbox'
            name: 'UI'
            message: 'Pick a frontend framework if you want'
            choices: [
                name: 'Twitter Bootstrap'
                value: 'boostrap'
                checked: true
            ,
                name: 'Foundation'
                value: 'foundation'
                checked: false
            ,
                name: 'Topcoat'
                value: 'topcoat'
                checked: false
            ,
                name: 'Pure'
                value: 'pureCSS'
                checked: false
            ]
        ]

    brunch: ->
        @_compile '_config.coffee'
        @log yosay('Brunch compiles all your things according to the 
             config.coffee file, vendor/ and bower_components/ are joined to 
             vendor.js and app.css according to filetypes.')

    app: ->
        @mkdir 'app'
        @mkdir 'app/scripts'
        @mkdir 'app/styles'
        @mkdir 'vendor'
        @_removeLodashCopyRoot [
            '_package.json'
            '_bower.json' 
            '_README.md'
        ]
        @_compile ['_index.jade'], '', 'app'

    projectfiles: ->
        @_addDotCopyRoot [
            'bowerrc'
            'editorconfig'
            'gitignore'
            'jshintrc'
            'gitattributes'
        ]

module.exports = BrunchGenerator
