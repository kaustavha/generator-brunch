yeoman = require "yeoman-generator"

class BrunchBase extends yeoman.generators.Base
    path = require "path"    
    yosay = require "yosay"
    chalk = require "chalk"
    wrench = require "wrench"
    fs = require 'fs'

    # Github
    proxy = process.env.http_proxy or process.env.HTTP_PROXY or process.env.https_proxy or process.env.HTTPS_PROXY or null
    githubOptions = version: "3.0.0"
    if proxy
      proxyUrl = url.parse proxy 
      githubOptions.proxy =
        host: proxyUrl.hostname
        port: proxyUrl.port
    GitHubApi = require "github"
    github = new GitHubApi githubOptions

    # Convenience function to run this.prompt and cast variables
    # Checks props in choices and casts to choice names
    # if prompt.choices exists then the selected choice/s will equal the promptname
    _ask: (prompts=[], codeBlock) =>
        done = @async()
        _assign = (prompt, props, codeBlock) =>
            propname = prompt.name
            if prompt.choices
                for choice in prompt.choices # set this.name for all choices
                    @[choice.name] = if props[propname].indexOf(choice.name) isnt -1 or props[propname] is choice.name then true else false
            @[propname] = props[propname] # set this.prompt.name to the selections in the answers hash
            return
        @prompt prompts, (props) =>
            for prompt in prompts 
                _assign prompt, props, codeBlock
            @prompts = prompts
            @props = props
            if codeBlock then codeBlock(@)
            return done()
        return

    _appNameFromDir: =>
        @appname = path.basename process.cwd()
        if !@appname? then @appname = 'app'
        @appname = @_.camelize @_.slugify @_.humanize @appname
        @appname
    
    # Convenience function for copying templates
    # passing templates as 'all' will result in all filepaths within being added | replaced with inbuilt directory()
    # runs the yeoman generator template function
    # removes _ in template file names
    # 
    _compile: (templates, src, dest) =>
        if dest and !fs.existsSync dest then @mkdir dest
        else if not dest then dest = ''
        if not src then src = ''
        src = src.toString()
        dest = dest.toString()
        _src = (tpl) ->
            if not src then return path.normalize tpl
            path.join src, tpl
        _dest = (tpl) ->
            # Normalize template names, i.e. '_x.y' -> 'x.y'
            if tpl.substring(0, 1) is '_' then tpl = tpl.substring 1, tpl.length
            if not dest then return path.normalize tpl
            path.join dest, tpl
        _copy = (tpl) =>
            if not tpl then tpl = ''
            if typeof tpl isnt 'string' then tpl = tpl.toString()
            @template _src(tpl), _dest(tpl)
        
        if typeof templates is 'string'
            if templates is '*'
                src = path.join process.cwd(), src 
                templates = fs.readdirSync src
                for tpl in templates
                    _copy tpl
            else
                tpl = templates
                return _copy tpl

        if typeof templates is 'object' # array of files to copy
            for tpl in templates
                _copy tpl
    # incomplete
    _generateSrcAndTest: (tpls, src, dest) =>
        __generateSrcAndTest = (tpl, src, dest) =>
            testPath = src
            if typeof tpl is 'string'
                if @coffeescript then ext = '.coffee'
                else if @icedcoffeescript then ext = '.ic'
                else if @livescript then ext = '.live'
                else if @javascript then ext = '.js'
                else ext = ''
                testPath += ext

                testPath += ext

            _compile tpls, src, dest

    _githubUserInfo: (name, cb) ->
        github.user.getFrom user: name, (err, res) ->
            if err
                throw new Error(err.message + "\n\nCannot fetch your github profile. Make sure you've typed it correctly.")
            cb JSON.parse(JSON.stringify(res)) if cb?

    # File rewriter
    # @args Object object with the following key-values
    #    file String file to rewite
    #    needle String line to look for 
    #    spliceable String Line to insert before needle
    _rewrite: (args) ->
        # js y u no escape reg exes?
        _escapeRegExp = (str) -> str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&'
        _rewriteFile = (args) ->
            re = new RegExp args.splicable.map (line) ->
                '\s*' + _escapeRegExp line
            .join '\n'

            if re.test args.haystack
                return args.haystack
            
            lines = args.haystack.split '\n'

            needleIndex = 0
            lines.forEach (line, i) ->
                if line.indexOf args.needle isnt -1
                    needleIndex = i
                    return

            spaces = 0
            spaceStr = ''
            while lines[needleIndex].charAt spaces is ' '
                spaces += 1
                spaceStr += ' '

            lines.splice needleIndex, 0, args.splicable.map (line) ->
                spaceStr + line
            .join '\n'

            lines.join '\n'


        args.path = args.path || process.cwd()
        fullPath = path.join args.path, args.file

        args.haystack = fs.readFileSync fullPath, 'utf8'
        body = _rewriteFile args

        fs.writeFileSync fullPath, body

module.exports = BrunchBase
