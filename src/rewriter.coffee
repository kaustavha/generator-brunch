wrench = require "wrench"
path = require 'path'
fs = require 'fs'

# File rewriter
# @param {Object} args Mapping with the foll. props
#   @key file @val {String} file to rewite
#   @key needle @val {String} line to look for 
#   @key splicable @val {Array} line|s to insert, elements in arr should be strings
# e.g args = {file: 'package.json', 
#             needle: '"dependencies"', 
#             splicable: ["a": "1.0.0", "b": "*"]}
rewriter = (args) ->
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

module.exports = rewriter
