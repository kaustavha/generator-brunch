class Utilities
    wrench = require 'wrench'
    {spawn} = require 'child_process'
    path = require 'path'
    fs = require 'fs'

    # File rewriter
    # @param {Object} args - Mapping with the foll. props
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
        if d and a and p and r is false
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

    # function to remove lines from a file
    # @param {string|array} @lines - line/s to remove from the file, can be word/phrase present in the line
    # @param {string} filepath - path to the file to rewrite
    lineRemover: (@lines, filepath) ->
        filepath = path.normalize filepath
        tmpFile = filepath + '.temp'
        l = new wrench.LineReader filepath
        switch lines.length
            when 0 then return
            when 1
                while l.hasNextLine()
                    line = l.getNextLine()
                    if line.indexOf(@lines) is -1
                        fs.appendFileSync tmpFile, line + '\n'
            else
                while l.hasNextLine()
                    line = l.getNextLine()
                    @append = true
                    @lines.forEach (lineToCheckFor) ->
                        if line.indexOf(lineToCheckFor) isnt -1
                            @append = false
                            @lines.splice @lines.indexOf(lineToCheckFor), 1 # minor, probably pointless optimization
                    if @append then fs.appendFileSync tmpFile, line + '\n'
        fs.unlinkSync filepath
        fs.renameSync tmpFile, filepath

    # @param {string} dep - valid dependency name
    # @param {string} cmd - package manager to search in e.g bower | npm
    # @param {function} @cb - callback to pass latest version number to
    # @var {boolean} ret - variable declaration, not an argument
    # @return {string} v - latest version of dependency or '*'
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
    # @param {Array|string} deps - Dependencies to inject
    # @param {string} type - Package managaer e.g bower | npm
    # @param {string} logic - var to check for when running _ through the file
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

        recurser = (@arr) =>
            if @arr.length is 1
                @end arr[0]
            else
                dep = @arr.pop()
                @getVersion dep, @type, (v) =>
                    @args.splicable.push '"' + dep + '": "' + v + '",'
                    recurser @arr

        @args.splicable.push "<% if (#{logic}) { %>" if logic
        if typeof(deps) is 'object' # Array...
            recurser deps
            # l = deps.length
            # deps.forEach (dep) =>
            #     if dep is deps[l-1]
            #         @end dep
            #     else
            #         @getVersion dep, @type, (v) =>
            #             @args.splicable.push '"' + dep + '": "' + v + '",'
        else if typeof(deps) is 'string'
            @end deps

    # convenience for injecting bower deps wrapped in an if statement of the same name
    bowerInjector: (name) ->
        @injectDeps name, 'bower', name

    # Takes a path to a JSON file for npm/bower
    # Updates all the dependencies in it
    JSONhandler: (filename, @type) ->
        file = fs.readFileSync filename
        @json = JSON.parse file
        deps = json.dependencies
        @newDeps = {}
        @end = (@dep) =>
            @getVersion @dep, @type, (v) =>
                @newDeps[@dep] = v
                @json.dependencies = {}
                @json.dependencies = @newDeps
                fs.writeFileSync filename + '.tmp', @json
                fs.unlinkSync fileName
                fs.renameSync filename + '.tmp', filename
        recurser = (deps) =>
            if deps.length is 1
                @end arr[0]
            else
                @dep = @deps.pop()
                @getVersion @dep, @type, (v) =>
                    @newDeps[@dep] = v

        deps = deps.keys()
        recurser deps

    # coffeescript files in cwd to js in ./app
    copyAndTranspile: (fileName) ->
        spawn 'coffee', ['-c', '-b', '-w', '-o', './app', fileName]

module.exports = Utilities
