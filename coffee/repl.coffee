###
 REPL simulator for web demo.
###
class facebook_terminal.REPL
  constructor: () ->
  
  start: (options)->
    options.input.setCallback(@input)
    @output = options.output
    @evaluate = options.eval
    @prompt = options.prompt || "> "
    #prompt: "> ",
    #output: process.stdout,
    #eval: @evaluate
  
  input: (value)=>
    @output.write.call(@output, @prompt + value)
    cmd = "(#{value} )"
    @evaluate cmd, null, null, (__, value)=>
      @output.write.call(@output, value)



