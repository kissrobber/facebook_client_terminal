fs = require 'fs'
async = require 'async'
{print} = require 'sys'
{spawn} = require 'child_process'

build = (callback) ->
  coffee = spawn 'coffee', ['-c', '-o', 'js', 'coffee']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

# buildTemplates = (callback) ->
#   eco = require 'eco'
#   compile = (name) ->
#     (callback) ->
#       fs.readFile "coffee/templates/#{name}.eco", "utf8", (err, data) ->
#         if err then callback err
#         else
#           callback null, "#{name}:#{eco.precompile(data)}"
#   async.parallel [
#     compile("lines")
#     compile("prompt")
#   ], (err, results)->
#     if err
#       process.stderr.write err.toString()
#     else
#       fs.writeFile "js/templates.js", "window.JST = {#{results.join(',')}};", callback

task 'sbuild', 'Build js/ from coffee/', ->
  build()
  # buildTemplates()

