#     imgflo-server - Image-processing server
#     (c) 2014 The Grid
#     imgflo-server may be freely distributed under the MIT license

async = require 'async'
pkginfo = (require 'pkginfo')(module, 'version')
path = require 'path'
child_process = require 'child_process'
fs = require 'fs'

installdir = __dirname + '/../install/'
projectdir = __dirname + '/..'

# Interface for Processors
class Processor
    constructor: (verbose) ->
        @verbose = verbose

    # FIXME: clean up interface
    # callback should be called with (err, error_string)
    process: (outputFile, outType, graph, iips, inputFile, inputType, callback) ->
        throw new Error 'Processor.process() not implemented'

clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime())

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags)

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance


gitDescribe = (path, callback) ->
    cmd = 'git describe --tags'
    child_process.exec cmd, { cwd: path }, (err, stdout, stderr) ->
        stdout = stdout.replace '\n', ''
        return callback err, stdout

getGitVersions = (callback) ->
  info =
       npm: module.exports.version
  names = [ 'server', 'runtime',
          'dependencies',
          'gegl',
          'babl'
  ]
  paths = [ './', 'runtime',
#          'runtime/dependencies',
#          'runtime/dependencies/gegl',
#          'runtime/dependencies/babl'
  ]
  paths = (path.join projectdir, p for p in paths)

  async.map paths, gitDescribe, (err, results) ->
      for i in [0...results.length]
          name = names[i]
          info[name] = results[i]

      callback err, info

getInstalledVersions = (callback) ->
    p = path.join installdir, 'imgflo.versions.json'
    fs.readFile p, (err, content) ->
        return callback err, null if err
        try
            callback null, JSON.parse content
        catch e
            callback e, null

updateInstalledVersions = (callback) ->

    fs.mkdir installdir, (err) ->
        return callback err, null if err and err.code != 'EEXIST'
        p = path.join installdir, 'imgflo.versions.json'
        getGitVersions (err, info) ->
          return callback err, null if err
          c = JSON.stringify info
          fs.writeFile p, c, (err) ->
              return callback err, null if err
              return callback null, p

exports.clone = clone
exports.Processor = Processor
exports.getInstalledVersions = getInstalledVersions
exports.updateInstalledVersions = updateInstalledVersions
exports.installdir = installdir