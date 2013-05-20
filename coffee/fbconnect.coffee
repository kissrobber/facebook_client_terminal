###
 facebook connect
###
class FBConnect

  constructor: ->
    @logined = false
    @config = require('./config.json')

  is_login: (cb)->
    cb(@logined)

  login: (cb)->
    #TODO check server
    console.log "Login server is ready. So go #{@login_url()}"
    cb(null)

  instruct_login: (cb)->
    #TODO check server
    console.log "Fisrt, you should login with Facebook. Go to #{@login_url()}"
    cb(null)
 
  login_url: ->
    "http://#{@config.http_server_host}:#{@config.http_server_port}/"

  set_access_token: (accesss_token)->
    FB.setAccessToken(accesss_token)
    @logined = true

module.exports = FBConnect;
