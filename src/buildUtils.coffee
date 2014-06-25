Promise = require 'bluebird'
wrench = require 'wrench'
{spawn} = require 'child_process'
path = require 'path'
fs = require 'fs'

class Utilities
    # File rewriter
    # @param {Object} args Mapping with the foll. props
    #   @key file @val {String} file to rewite
    #   @key path @val {String} OPTIONAL path of the file, useful to sep. path from name in code
    #   @key needle @val {String} line to look for 
    #   @key splicable @val {Array} line|s to insert, elements in arr should be strings
    #   @key [d|a|p|r] || [delete|append|prepend|replace] @val {boolean}  
    # e.g args = {file: 'package.json', 
    #             needle: '"dependencies"',
    #             splicable: ["a": "1.0.0", "b": "*"],
    #             a: true}
    rewriter: (args) ->
        d = if args.d or args.delete then true else false
        a = if args.a or args.append then true else false
        p = if args.p or args.prepend then true else false
        r = if args.r or args.replace then true else false
        args.path = args.path || process.cwd()
        fullPath = path.join args.path, args.file
        tmpFile = args.file + '.temp'
        if fs.existsSync tmpFile
            fs.unlinkSync tmpFile
        l = new wrench.LineReader fullPath
        while l.hasNextLine()
            line = l.getNextLine()
            if line.indexOf(args.needle) isnt -1
                if d then return # dont write the line
                
                spaces = 0
                spaceChar = ' '
                tabChar = ' '
                switch line.charAt(spaces)
                    when tabChar
                        spaceStr = tabChar
                        while line.charAt(spaces) is '  ' 
                            spaces += 1
                            spaceStr += tabChar
                    when ' '
                        spaceStr = '  '
                        while line.charAt(spaces) is ' '
                            spaces += 1
                            spaceStr += ' '
                
                if a
                    fs.appendFileSync tmpFile, line + '\n'
                    args.splicable.forEach (lineToInject) ->
                        fs.appendFileSync tmpFile, spaceStr + lineToInject + '\n'
                else if p
                    args.splicable.forEach (lineToInject) ->
                        fs.appendFileSync tmpFile, spaceStr + lineToInject + '\n'
                    fs.appendFileSync tmpFile, line + '\n'
                else if r
                    args.splicable.forEach (lineToInject) ->
                        fs.appendFileSync tmpFile, lineToInject + '\n'
            else 
                fs.appendFileSync tmpFile, line + '\n'
        fs.unlinkSync fullPath
        fs.renameSync tmpFile, fullPath

        console.log 'Rewrote file ' + fullPath
        contents = ''
        args.splicable.forEach (l) ->
            contents += l + ' |/n| '
        console.log 'With contents ' + contents

    # @param dep {string} valid dependency name
    # @param cmd {string} package manager to search in e.g bower | npm
    # @return v {string} latest version of dependency or *
    getVersion: (dep, cmd, @cb, ret=false) ->
        vd = spawn cmd, ['info', dep, '--json'], {uid: if cmd is 'npm' then 0 else 1000}
        ret = =>
            @ret = true
            @cb '*'
        # timeout for network latency 
        setTimeout ret, 1000

        vd.stdout.on 'data', (d) =>
            data = d.toString()
            data = JSON.parse data
            l = data.versions.length - 1
            v = data.versions[l]
            @cb v if not @ret
        vd.stdout.on 'err', (err) -> @cb '*' if not @ret

    # Function to inject newest versioned dependencies into bower/npm json files
    # @param deps {Array|string} Dependencies to inject
    # @param type {string} Package managaer e.g bower | npm
    # @param logic {string} var to check for when running _ through the file
    injectDeps: (deps, @type, logic) ->
        switch @type
            when 'bower' then fileName = '_bower.json'
            when 'npm' then fileName = '_package.json'
        @args = {}
        @args.file = './app/templates/'
        @args.file += fileName
        @args.needle = '"dependencies":'
        @args.append = true
        @args.splicable = []
        @end = (dep) =>
            @getVersion dep, @type, (v) =>
                @args.splicable.push '"' + dep + '": "' + v + '",'
                @args.splicable.push '<% } %>' if logic
                console.log 'Calling rewriter'
                @rewriter @args

        @args.splicable.push "<% if (#{logic}) { %>" if logic
        if typeof(deps) is 'object' # Array...
            l = deps.length
            deps.forEach (dep) =>
                if dep is deps[l-1]
                    @end dep
                else
                    @getVersion dep, @type, (v) =>
                        @args.splicable.push '"' + dep + '": "' + v + '",'
        else if typeof(deps) is 'string'
            @end deps

    # convenience for injecting bower deps wrapped in an if statement of the same name
    bowerInjector: (name) ->
        @injectDeps name, 'bower', name

    copyAndTranspile: (fileName) ->
        spawn 'coffee', ['-c', '-b', '-w', '-o', './app', fileName]

module.exports = Utilities
