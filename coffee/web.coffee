###
 Setup globals to fool me into thinking I'm on a nodejs.
 and do something related to web.
###
window.module =
  exports: {}

window.process =
  stdin: null
  stdout: null
  exit: ()->
window.global = window

window.require = (name)->
  switch name
    when "repl"
      new facebook_terminal.REPL()
    when "./libs/underscore.js"
      return window._us
    when "fb"
      return window.FB
    when './fbconnect'
      return facebook_terminal.WebFBConnect
    when './loginserver.js'
      return null
    else
      throw "error. module not found: #{name}"

window.console.log = (value)->
  process.stdout.write(value)

window._us = _

window.facebook_terminal = {}
window.JST = {}

window.is_web = true

window.fbAsyncInit = ->
  FB.init
    appId      : '202146573265908'
    channelUrl : '//static.dev/channel.html'
    status     : true
    cookie     : true
    xfbml      : true

  csl = $('<div class="console">')
  div = $('#console')
  text = div.text()
  div.empty()
  div.append(csl)

  controller  = csl.console({
    promptLabel: '$ '
    welcomeMessage: text
    commandValidate: (line)->
      return true
    commandHandle:(line, report)->
      window.process.stdin.input(line)
      return
    cols: 40
    autofocus: true
    # completeHandle:(prefix)->
    animateScroll:true
    promptHistory:true
  })
  
  window.process.stdin = new facebook_terminal.STDIN()
  window.process.stdout = new facebook_terminal.STDOUT((value)->
    controller.output(value, "jquery-console-message-value");
  )

  ft = window.module.exports
  ft.start()

