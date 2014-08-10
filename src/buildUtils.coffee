class Utilities
    wrench = require 'wrench'
    {spawn} = require 'child_process'
    path = require 'path'
    fs = require 'fs'
    Q = require 'q'

    # File rewriter
    # @param {Object} args - Mapping with the foll. props
    #   @key file @val {String} file to rewite
    #   @key path @val {String} OPTIONAL path of the file, useful to sep. path from name in code
    #   @key needle @val {String} line to look for 
    #   @key splicable @val {Array} line|s to insert, elements in arr should be strings
    #   @key [d|a|p|r] || [delete|append|prepend|replace] @val OPTIONAL {boolean}  
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
                tabChar = '	'
                endingBrace = ''
                switch line.charAt(spaces)
                    when tabChar
                        spaceStr = tabChar
                        while line.charAt(spaces) is tabChar
                            spaces += 1
                            spaceStr += tabChar
                    when ' '
                        spaceStr = '  '
                        while line.charAt(spaces) is ' '
                            spaces += 1
                            spaceStr += spaceChar

                # In case we have an empty dependencies object, we wish to place deps into the {} not after
                if args.file.substr(-4) is 'json' and line.substr(-2) is '},'
                    line = line.substr(0, line.length - 2)
                    endingBrace += '  },'
                    appendEndingBrace = true

                
                if a
                    console.log line
                    fs.appendFileSync tmpFile, line + '\n'
                    args.splicable.forEach (lineToInject) ->
                        fs.appendFileSync tmpFile, spaceStr + lineToInject + '\n'
                    if appendEndingBrace then fs.appendFileSync tmpFile, endingBrace + '\n'
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
    getVersion: (dep, cmd, ret=false) =>
        deffered = Q.defer()
        vd = spawn cmd, ['info', dep, '--json'], {uid: if cmd is 'npm' then 0 else 1000}
        # timeout for network latency 
        ret = =>
            if @ret then return
            @ret = true
            console.log "#{dep} didn't return a version"
            deffered.resolve '*'
        # setTimeout ret, 5000

        vd.stdout.on 'data', (d) =>
            data = d.toString()
            data = JSON.parse data
            if cmd is 'bower'
                v = data.versions[0]
            else
                l = data.versions.length - 1
                v = data.versions[l]
            # Re-assure me
            console.log "Retrieved version - #{dep}: #{v}"
            deffered.resolve v

        vd.stdout.on 'err', (err) =>
            deffered.resolve '*'

        deffered.promise

    # Sets defaults for the args object meant for the file rewriter function
    argsDefaultsSetter: (type, path) =>
        switch type
            when 'bower' then fileName = '_bower.json'
            when 'npm' then fileName = '_package.json'
        @args = {}
        @args.file = path || './app/templates/'
        @args.file += fileName
        @args.needle = '"dependencies":'
        @args.append = true
        @args.splicable = []
        @args

    # Function to inject newest versioned dependencies into bower/npm json files
    # Useful if you want to inject an array of deps with no {yeoman underscore engine} conditional checks
    # or wrapped in a single conditional check into a package.json or bower.json file
    # @param {Array|string} deps - Dependencies to inject
    # @param {string} type - Package managaer e.g bower | npm
    # @param {string} OPTIONAL logic - Variable to check for when running _ through the file
    # @param {string} OPTIONAL path - Filepath
    dependencyInjector: (deps, @type, logic, path) ->
        deffered = Q.defer()
        @argsDefaultsSetter @type, path
        @end = (dep) =>
            @getVersion dep, @type
            .then (v) =>
                @args.splicable.push '"' + dep + '": "' + v + '",'
                @args.splicable.push '<% } %>' if logic
                @rewriter @args
                deffered.resolve()
            .done()

        recurser = (@arr) =>
            if @arr.length is 1
                @end arr[0]
            else
                dep = @arr.pop()
                @getVersion dep, @type
                .then (v) =>
                    @args.splicable.push '"' + dep + '": "' + v + '",'                    
                    recurser @arr

        @args.splicable.push "<% if (#{logic}) { %>" if logic
        if typeof(deps) is 'object' # Array...
            recurser deps
        else if typeof(deps) is 'string'
            @end deps

        deffered.promise

    # if no condition, use dep name as condition
    conditionalDependencyInjector: (deps, @type, @condition, path) ->
        deffered = Q.defer()
        @argsDefaultsSetter @type, path
        recurser = (@arr) =>
            if @arr.length is 0
                @rewriter @args
                deffered.resolve()
            else
                @dep = @arr.pop()
                @logic = @condition || @dep
                @getVersion @dep, @type
                .then (v) =>
                    @args.splicable.push "<% if (#{@logic}) { %>" if @logic
                    @args.splicable.push '"' + @dep + '": "' + v + '",'
                    @args.splicable.push '<% } %>' if @logic
                    recurser @arr

        recurser deps
        deffered.promise


    # convenience for injecting bower deps wrapped in an if statement of the same name
    bowerInjector: (name) ->
        @injectDeps name, 'bower', name


    # Coffeescript Object -> JSON parseable by npm/bower/nw
    # @name string Name of the file of to convert e.g 'bower' if bower.cson
    # @inDir string (optional) Location of input file
    # @outDir string (optional) Output directory
    # @outName string (optional) Output file name
    # @cb function (optional) Callback function to execute on completion
    # e.g fromCSON _bower, src, app, bower, ->
    #         child_process.spawn 'bower', ['install']
    fromCSON: (name, inDir, outDir, outName) ->
        deffered = Q.defer()
        console.log "Converting #{name}.cson to json"

        nameType = typeof name
        switch nameType
            when 'object'
                name.forEach (n) -> fromCSON n, inDir, outDir, outName
            when 'string'
                #check if name has suffix, remove if it does i.e a.json -> a
                if name.substring((name.length - 5), (name.length - 4)) is '.'
                    name = name.substring name.length - 5, 0
                else if name is '*'
                    file = readdirSyncRecursive inDir
                    files.forEach (file) -> fromCSON fileName, inDir, ourDir, outName      

        switch arguments.length
            when 1
                inDir = ''
                outDir = ''
                outName = name
            when 2
                outDir = ''
                outName = name
            when 3
                outName = name

        inFileName = name.toString() + '.cson'
        inFilePath = path.join inDir, inFileName
        if not fs.existsSync inFilePath then throw new Error "file #{inFileName} does not exist"
        outFileName = outName.toString() + '.json'
        outFilePath = path.join outDir, outFileName
        if fs.existsSync outFilePath then fs.unlinkSync outFilePath
        tempFilename = name + '.js'
        tempFilePath = path.join inDir, tempFilename
        if fs.existsSync tempFilePath then fs.unlinkSync tempFilePath
        process = spawn 'coffee', ['-bc', inFilePath]
        process.on 'exit', (res) ->            
            tempFile = fs.readFileSync tempFilePath
            data = tempFile.toString() # stringify buffer
            pos = data.indexOf '\n' # position of end of first line which is 'generated by coffescript ver. no.'
            if pos isnt -1
                data = data.substr pos + 2 #extract desired string, pos + 2 is done to remove /n and (
                data = data.substr 0, data.length - 3 # remove ); at end
            # add a newline at the end of the file
            data += '\n'
            fs.writeFileSync outFilePath, data
            fs.unlinkSync tempFilePath
            deffered.resolve()

        deffered.promise

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

module.exports = new Utilities
