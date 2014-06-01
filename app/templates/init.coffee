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

githubUserInfo = (name, cb) ->
    github.user.getFrom user: name, (err, res) ->
        if err
            throw new Error(err.message + "\n\nCannot fetch your github profile. Make sure you've typed it correctly.")
        cb JSON.parse(JSON.stringify(res))
        return
    return

init = ->
    @pkg = require("../package.json")
    @on "end", ->
        @installDependencies() unless @options["skip-install"]
    # Convenience function to run this.prompt and cast variables
    # Checks props in choices and casts to choice names if prompt.choices exists
    @ask = (prompts=[], codeBlock) =>
        done = @async()
        _assign = (prompt, props, codeBlock) =>            
            propname = prompt.name
            if not @decisions then @decisions = []

            if prompt.choices
                for p in props[propname]
                    decisions[p] = true
                    @[p] = true
            @[propname] = props[propname]
            @decisions[propname] = props[propname]
            if codeBlock then codeBlock()

        @prompt prompts, (props) =>
            for prompt in prompts 
                ###if prompt.choices
                    for prompt in prompt.choices
                        _assign prompt, props, codeBlock
                else###
                _assign prompt, props, codeBlock
            return done()
        return

    @appNameFromDir = =>
        @appname = path.basename process.cwd()
        if !@appname? then @appname = 'app'
        @appname = @_.camelize @_.slugify @_.humanize @appname
        return @appname
    
    # Convenience function for copying templates
    # passing templates as 'all' will result in all filepaths within being added
    @compile = (templates, src, dest) =>
        if dest and !fs.existsSync dest then @mkdir dest
        else if not dest then dest = ''
        if not src then src = ''
        src = src.toString()
        dest = dest.toString()
        _src = (tpl) -> path.join src, tpl
        _dest = (tpl) ->                
            # Normalize template names, i.e. '_x.y' -> 'x.y'
            if tpl.substring(0, 1) is '_' then tpl = tpl.substring 1, tpl.length
            path.join dest, tpl
        _copy = (tpl) =>
            if not tpl then tpl = ''
            if typeof tpl isnt 'string' then tpl = tpl.toString()
            @template _src(tpl), _dest(tpl)
        
        if typeof templates is 'string'
            ###if templates is 'all'
                templates = wrench.readdirSyncRecursive src###
            if templates is '*'
                src = path.join process.cwd(), src 
                templates = fs.readdirSync src
            else
                tpl = templates
                return _copy tpl
        if typeof templates is 'object' # array of files to copy
            for tpl in templates
                _copy tpl

module.exports = init