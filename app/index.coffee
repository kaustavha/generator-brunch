# Node requires
path = require "path"
yosay = require "yosay"

# Base utilities class
BrunchBase = require './base.js'

# Node webkit download info
nwv = 'v0.9.2'
nwBase = 'http://dl.node-webkit.org/' + nwv + '/node-webkit-' + nwv + '-'


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

    askForUIFramework: ->
        prompts = [
            type: 'checkbox'
            name: 'UI'
            message: 'Pick a frontend framework if you want'
            choices: [                
                name: 'Bootstrap'
                checked: true
            ,
                name: 'Foundation'
                checked: false
            ,                
                name: 'AngularStrap'
                checked: false
            ,
                name: 'Angular UI'
                checked: false
            ,
                name: 'Topcoat'
                checked: false
            ,
                name: 'Pure'
                checked: false
            ]
        ]
        @_ask prompts

    brunch: ->
        @_compile '_config.coffee'

    app: ->
        @mkdir 'app'
        @mkdir 'app/scripts'
        @mkdir 'app/styles'
        @mkdir 'vendor'
        @_compile ['_package.json', '_bower.json', '_README.md']
        @_compile ['_index.jade'], '', 'app'

    projectfiles: ->
        @copy "editorconfig", ".editorconfig"
        @copy "jshintrc", ".jshintrc"

module.exports = BrunchGenerator
