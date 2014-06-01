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

    askForExtras: ->
        prompts = [
            type: 'list'
            name: 'extras'
            message: 'Extras: Web -> Mobile | PC frameworks'
            choices: [
                name: 'Node-webkit'
                checked: true
            # ,
            #     name: 'Cordova'
            #     checked: false
            ,
                name: 'Neither'
                checked: false
            ]
#             ,
#             type: 'list'
#             name: 'scripts'
#             message: 'JS preprocessors'
#             choices: [
#                 name: 'CoffeeScript'
#                 checked: true
#             ,
#                 name: 'IcedCoffeeScript'
#                 checked: false
#             ,
#                 name: 'Livescript'
#                 checked: false
#             ]
#         ,
#             type: 'list'
#             name: 'styles'
#             message: 'CSS preprocessors'
#             choices: [
#                 name: 'Stylus'
#                 checked: true
#             ,
#                 name: 'SASS'
#                 checked: false
#             ,
#                 name: 'LESS'
#                 checked: false
#             ]
#         ,
#             type: 'list'
#             name: 'views'
#             message: 'HTML preprocessors'
#             choices: [
#                 name: 'JADE'
#                 checked: true
#             ,
#                 name: 'HAML'
#                 checked: false
#             ,
#                 name: 'Markdown'
#                 checked: false
#             ,
#                 name: 'Slim'
#                 checked: false
#             ]
        ]
        @_ask prompts, =>
            @config.set 'views', 'JADE'
            @config.set 'styles', 'Stylus'
            @config.set 'scripts', 'CoffeeScript'


    askForNW: ->
        if @extras is 'Node-webkit'
            prompts = [
                type: 'confirm'
                name: 'dlnw'
                message: 'Download latest node-webkit?'
                default: false
            ]
            @_ask prompts

    askForNWDetails: ->
        if @dlnw
            prompts = [
                type: 'checkbox'
                name: 'platforms'
                message: 'Which platform(s) do you wanna support?'
                choices: [
                    name: 'osx-ia32'
                    checked: true
                ,
                    name: 'linux-ia32'
                    checked: true
                ,   
                    name: 'linux-x64'
                    checked: true
                ,
                    name: 'win-ia32'
                    checked: true
                ]
                validate: (ans) ->
                    if ans.length < 1 
                        'You must pick one platform at least'
                    else true
            ]        
            @_ask prompts

#   askForCordova: ->
#         if @extras is 'Cordova'
#             prompts = [
#                 name: 'packagename'
#                 message: 'What would you like the package to be called?'
#                 default: 'io.cordova.' + @appName
#             ,
#                 type: 'checkbox'
#                 name: 'platforms'
#                 message: 'What platforms would you like to add support for?'
#                 choices: [
#                     name: 'android'
#                     checked: true
#                 ,
#                     name: 'ios'
#                     checked: true
#                 ,
#                     name: 'blackberry10'
#                     checked: false
#                 ,
#                     name: 'Windows Phone 7'
#                     value: 'wp7'
#                     checked: false
#                 ,
#                     name: 'Windows Phone 8'
#                     value: 'wp8'
#                     checked: false
#                 ]
#             ,
#                 type: 'checkbox'
#                 name: 'plugins'
#                 message: 'What plugins would you like to include by default'
#                 choices:[
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-device.git'
#                     name: 'Device Info'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-camera.git'
#                     name: 'Camera'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-contacts.git'
#                     name: 'Contacts'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-dialogs.git'
#                     name: 'Dialogs'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-geolocation.git'
#                     name: 'Geolocation'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-inappbrowser.git'
#                     name: 'In App Browser'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-media.git'
#                     name: 'Audio Handler (a.k.a Media on Cordova Docs)'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-media-capture.git'
#                     name: 'Media Capture'
#                     checked: false
#                 ,
#                     value: 'https://git-wip-us.apache.org/repos/asf/cordova-plugin-network-information.git'
#                     name: 'Network Information'
#                     checked: false
#                 ]
#             ]
#             @_ask prompts

#     cordova: ->        
#         if @extras is cordova
#             done = @async()
#             @log 'Creating cordova app:' + @appName
#             cwd = process.cwd()
#             try
#                 cordova.create cwd, @packagename, @appName, ->
#                     fs.unlinkSync cwd + '/www/js/index.js'
#                     fs.unlinkSync cwd + '/www/css/index.css'
#                     fs.unlinkSync cwd + '/www/index.html'
#             catch err
#                 console.error 'Failed to create cordova project: ' + err
#                 process.exit(1)
#             if !@platforms?
#                 return

#             if @platforms
#                 @log 'Adding platforms to cordova'
#                 @platforms.forEach (platform) ->
#                     try
#                         cordova.platform 'add', platform, ->
#                             console.log chalk.green('✔ ') + ' added ' + chalk.gray(platforms[index])
#                     catch err
#                         console.error 'Failed to add platform ' + platform + ': ' + err

#             if @plugins     
#                 @log 'Adding plugins to cordova'
#                 @plugins.forEach (plugin) ->
#                     try
#                         cordova.plugin 'add', plugin, ->
#                             @log chalk.green('✔ ') + ' added ' + chalk.gray(plugins[index])
#                     catch err
#                         console.error 'Failed to add plugin ' + plugin + ': ' + err

    askForModules: ->
        prompts = [
            type: 'checkbox'
            name: 'ngModules'
            message: 'Pick angular modules you want'
            choices: [
                name: 'ngRoute'
                checked: true
            ,
                name: 'ngAnimate'
                checked: false
            ,
                name: 'ngResource'
                checked: false
            ,
                name: 'ngCookies'
                checked: false
            ,
                name: 'ngTouch'
                checked: false
            ,
                name: 'ngSanitize'
                checked: false
            ,
                name: 'ngMock'
                checked: false
            ]
        ]
        @_ask prompts, =>
            @ngModules.forEach (module) =>
                @ngModules.splice @ngModules.indexOf(module), 1, "'#{module}'"

    askForDirStruct: ->
        prompts = [
            type: 'list'
            name: 'dirStruct'
            message: 'Pick a directory structure.'
            choices: [
                name: 'Traditional: Segregated by file type into scripts/views/styles'
                value: 'traditional'
                checked: false
            # ,
            #     name: 'Features: Angular way for module feature based applications'
            #     value: 'features'
            #     checked: true
            ]
        ]
        @_ask prompts, () =>
            # Sets .yo-rc.json
            @config.set 'dirStruct', @dirStruct

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
        @_compile ['_package.json', '_bower.json']
        @_compile ['_index.jade', '_app.coffee'], '', 'app'

    example: ->
        @directory 'example', 'app/example'

    nodeWebkit: ->
        done = @async()
        @mkdir 'node-webkit'
        if @dlnw
            platforms = ['osx-ia32', 'win-ia32', 'linux-ia32', 'linux-x64']

            platforms.forEach (platform) =>
                ext = if platform is platforms[2] or platform is platforms[3] then '.tar.gz' else '.zip'
                url = nwBase + platform + ext
                filePath = path.join 'node-webkit', platform
                @mkdir filePath
                @extract url, filePath, done

    projectfiles: ->
        @copy "editorconfig", ".editorconfig"
        @copy "jshintrc", ".jshintrc"

module.exports = BrunchGenerator
