# Yo man, wassup?
yeoman = require "yeoman-generator"

class BrunchBase extends yeoman.generators.NamedBase
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

    # Convenience function to run this.prompt, set the yo-rc.json 
    # config file and cast variables
    # Checks props in choices and casts to choice names
    # if prompt.choices exists then the selected choice/s will equal the promptname
    _ask: (prompts=[], codeBlock) =>
        done = @async()
        _set = (key, val) =>
            @config.set key, val
        _assign = (prompt, props) =>
            propname = prompt.name
            if prompt.choices
                for choice in prompt.choices # set this.name for all choices
                    bool = if props[propname].indexOf(choice.name) isnt -1 or props[propname] is choice.name then true else false
                    @[choice.value] = bool
                    _set choice.value, bool
            @[propname] = props[propname] # set this.prompt.name to the selections in the answers hash
            _set propname, props[propname]
            return
        @prompt prompts, (props) =>
            prompts.forEach (prompt) =>
                _assign prompt, props
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
    # @templates String or array of filenames
    # @src src in generator to copy from, defaults to app/templates
    # @dest destination, defaults to directory generator is called from
    # @opts key-value mapping of the following options
    #    @processor string 'template'|'copy' Run the _ engine through the file, or just copy it
    #    @renamer function|string|number Used to rename filenames that
    #             have similiar renaming schemes
    _compile: (templates, src, dest, opts) =>
        if dest and !fs.existsSync dest then @mkdir dest
        else if not dest then dest = ''
        if not src then src = ''
        src = src.toString()
        dest = dest.toString()
        _renamer = (tpl, renamer) ->
            if not renamer? then return tpl
            if typeof(renamer) is 'function'
                tpl = renamer(tpl)
            else if typeof(renamer) is 'string' or typeof(renamer) is 'number'
                if renamer is 'remove_' or renamer is 1
                    # '_x.y' -> 'x.y'
                    tpl = tpl.substring(1, tpl.length)
                else if renamer is 'add.' or renamer is 2
                    # 'x' -> '.x'
                    tpl = ".#{tpl}"
        _src = (tpl) ->
            if not src then return path.normalize tpl
            path.join src, tpl
        _dest = (tpl) ->
            if opts? and opts.renamer?
                tpl = _renamer(tpl, opts.renamer)
            if not dest then return path.normalize tpl
            path.join dest, tpl
        _copy = (tpl) =>
            if not tpl then tpl = ''
            if typeof tpl isnt 'string' then tpl = tpl.toString()
            if opts.processor is 'template'
                @template _src(tpl), _dest(tpl)
            else if opts.processor is 'copy'
                @copy _src(tpl), _dest(tpl)
            else 
                @copy _src(tpl), _dest(tpl)


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


    # More convenience
    _addDotCopyRoot: (tpls, renamer) =>
        _compile tpls, '', '', {renamer: 'add.', processor: 'copy'}
    _removeLodashTemplateRoot: (tpls) =>
        _compile tpls, '', '', {renamer: 'remove_', processor: 'template'}
    


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
    # @param {Object} args Mapping with the foll. props
    #   @key file @val {String} file to rewite
    #   @key needle @val {String} line to look for 
    #   @key splicable @val {String} line|s to insert
    #   @key replace @val {String} Choices are:
    #                        'a' - append
    #                        'p' - prepend
    #                        'r' - replace
    #                        'd' - delete
    _rewrite: (args) ->
        # js y u no scape reg xs?
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

            ar = args.replace
            switch ar
                when 'd'
                    index = needleIndex
                    count = 1
                when 'r'
                    index = needleIndex
                    count = 1
                when 'a'
                    index = needleIndex + 1
                    count = 0
                when 'p'
                    index = needleIndex
                    count = 0

            lines.splice index, count, args.splicable.map((line) ->
                spaceStr + line
            ).join '\n'

            lines.join '\n'

        args.path = args.path || process.cwd()
        fullPath = path.join args.path, args.file

        args.haystack = fs.readFileSync fullPath, 'utf8'
        body = _rewriteFile args

        fs.writeFileSync fullPath, body

module.exports = BrunchBase
