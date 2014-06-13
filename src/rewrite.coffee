fs = require 'fs'
path = require 'path'
wrench = require 'wrench'
# es = require 'event-stream'
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
rewrite = (args) ->
    # js y u no scape reg xs?
    _escapeRegExp = (str) -> str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&'
    _rewriteFile = (args, data) ->
        # re = new RegExp args.splicable.map((line) ->
        #     '\s*' + _escapeRegExp line
        # ).join '\n'

        # if re.test args.haystack
        #     return args.haystack
        args.haystack = data.toString()
        lines = args.haystack.split '\n'

        needleIndex = 0
        lines.forEach (line, i) ->
            if line.indexOf(args.needle) isnt -1
                needleIndex = i
            return

        spaces = 0
        spaceStr = ''
        while lines[needleIndex].charAt spaces is ' '
            spaces += 1

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

        while spaces isnt 0
            spaceStr += ' '
            spaces--
            
        lines.splice index, count, args.splicable.map((line) ->
            spaceStr + line
        ).join '\n'

        lines.join '\n'


    args.path = args.path || process.cwd()
    fullPath = path.join args.path, args.file
    @args = args
    tmpFile = args.file + '.temp' 
    l = new wrench.LineReader fullPath
    while l.hasNextLine()
        line = l.getNextLine()
        console.log line
        fs.appendFileSync tmpFile, line + '\n'
        console.log '< -- break --->'
        console.log line

    # fs.createReadStream(fullPath)
    #     .pipe es.mapSync (data) ->
    #         @args.haystack = data.toString()
    #         data = _rewriteFile @args
    #         data
    #     .pipe fs.createWriteStream fullPath + 'x'

    # data = fs.readFileSync fullPath
    # @args.haystack = new Buffer data.toString()
    # data = new Buffer _rewriteFile @args, data
    # console.log data

    # args.haystack = fs.readFileSync fullPath, 'utf8'
    # body = _rewriteFile args
    # @args = args
    # fs.readFile fullPath, (err, data) =>
    #     if err then throw err
    #     console.log data
    #     console.log fullPath
    #     @args.haystack = data.toString() # Stringify buffer
    #     console.log @args
    #     data = _rewriteFile @args
    #     fs.writeFile fullPath, data, (err) -> if err then throw err else console.log 'Package saved.'

    # ws = fs.createWriteStream fullPath, flags: 'w'
    # rs = fs.createReadStream fullPath
    # rs.pipe(_rewriteFile).pipe(ws)
    # body = _rewriteFile args
    # fs.writeFileSync fullPath, body
module.exports = rewrite