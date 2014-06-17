wrench = require 'wrench'
path = require 'path'
fs = require 'fs'

class utils
    # File rewriter
    # @param {Object} args Mapping with the foll. props
    #   @key file @val {String} file to rewite
    #   @key needle @val {String} line to look for 
    #   @key splicable @val {Array} line|s to insert, elements in arr should be strings
    # e.g args = {file: 'package.json', 
    #             needle: '"dependencies"', 
    #             splicable: ["a": "1.0.0", "b": "*"]}
    rewriter: (args) ->
        args.path = args.path || process.cwd()
        fullPath = path.join args.path, args.file
        tmpFile = args.file + '.temp'
        if fs.existsSync tmpFile
            fs.unlinkSync tmpFile
        l = new wrench.LineReader fullPath
        while l.hasNextLine()
            line = l.getNextLine()
            if line.indexOf(args.needle) isnt -1
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
                fs.appendFileSync tmpFile, line + '\n'
                args.splicable.forEach (lineToInject) ->
                    fs.appendFileSync tmpFile, spaceStr + lineToInject + '\n'
            else 
                fs.appendFileSync tmpFile, line + '\n'
        fs.unlinkSync fullPath
        fs.renameSync tmpFile, fullPath

    # @param dep {string} valid dependency name
    # @param cmd {string} package manager to search in e.g bower | npm
    # @return v {string} latest version of dependency or *
    getVersion: (dep, cmd) ->
        versionData = spawn cmd, ['info', dep, '--json']
        versionData.stdout.on 'data', (data) =>
            data = JSON.parse(data)
            l = data.versions.length - 1
            v = data.versions[l] || '*'

    # Function to inject newest versioned dependencies into bower/npm json files
    # @param deps {Array|string} Dependencies to inject
    # @param type {string} Package managaer e.g bower | npm
    # @param logic {string} var to check for when running _ through the file
    injectDeps: (deps, type, logic) ->
        switch type
            when 'bower' then fileName = '_bower.json'
            when 'npm' then filename = '_package.json'
        @args = {}
        @args.file = './app/templates/'
        @args.file += fileName
        @args.needle = '"dependencies":'
        @args.splicable = []
        if logic?
            @args.splicable.push "<% if (#{logic}) { %>"
        if typeof(deps) is 'object'
            @type = type
            deps.forEach (dep) =>
                v = getVersion dep, @type
                @args.splicable.push '"' + dependency + '": "' + v + '",'
        else if typeof(deps) is 'string'
            v = getVersion deps, type
            @args.splicable.push '"' + dependency + '": "' + v + '",'
        if logic?
            @args.splicable.push '<% } %>'
        rewriter @args

    # convenience for injecting bower deps wrapped in an if statement of the same name
    bowerInjector: (name) ->
        injectDeps name, 'bower', name

    copyAndTranspile: (fileName) ->
        spawn 'coffee', ['-c', '-b', '-w', '-o', './app', fileName]

module.exports = utils