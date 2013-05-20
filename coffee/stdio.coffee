###
 STDIN and STDOUT simulator for web demo.
###
class facebook_terminal.STDIN
  constructor: (cb)->
  input: (value)=>
    @callback(value)
  setCallback: (cb)->
    @callback = cb

class facebook_terminal.STDOUT
  constructor: (@callback)->
  write: (value)->
    @callback(value) unless value == undefined
