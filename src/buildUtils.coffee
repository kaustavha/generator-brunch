Promise = require 'bluebird'
wrench = require 'wrench'
{spawn} = require 'child_process'
blueSpawn = Promise.promisify(require('child_process').spawn)
path = require 'path'
fs = require 'fs'

module.exports = {
    # File rewriter
    # @param {Object} args Mapping with the foll. props
    #   @key file @val {String} file to rewite
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

    # @param dep {string} valid dependency name
    # @param cmd {string} package manager to search in e.g bower | npm
    # @return v {string} latest version of dependency or *
    getVersion: (dep, cmd, cb) ->
        blueSpawn cmd, ['info', dep, '--json'], {uid: if cmd is 'npm' then 0 else 1000}
            .then (res) ->
                data = JSON.parse res[0]
                l = data.versions.length - 1
                v = data.versions[l]
            .then (res) -> cb res

    # Function to inject newest versioned dependencies into bower/npm json files
    # @param deps {Array|string} Dependencies to inject
    # @param type {string} Package managaer e.g bower | npm
    # @param logic {string} var to check for when running _ through the file
    injectDeps: (deps, type, logic) ->
        @type = type
        switch type
            when 'bower' then fileName = '_bower.json'
            when 'npm' then fileName = '_package.json'
        _getVerPushDep = (dep) =>
            @getVersion dep, @type, (res) =>
                v = res
                @args.splicable.push '"' + dep + '": "' + v + '",'
        @args = {}
        @args.file = './app/templates/'
        @args.file += fileName
        @args.needle = '"dependencies":'
        @args.append = true
        @args.splicable = []

        @args.splicable.push "<% if (#{logic}) { %>" if logic
        if typeof(deps) is 'object' # Array...
            deps.forEach (dep) =>
                _getVerPushDep dep
        else if typeof(deps) is 'string'
            _getVerPushDep deps
        @args.splicable.push '<% } %>' if logic

        @rewriter @args

    # convenience for injecting bower deps wrapped in an if statement of the same name
    bowerInjector: (name) ->
        @injectDeps name, 'bower', name

    copyAndTranspile: (fileName) ->
        spawn 'coffee', ['-c', '-b', '-w', '-o', './app', fileName]
}
