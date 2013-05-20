###
 facebook connect for web demo
###
class facebook_terminal.WebFBConnect

  constructor: ->
    @logined = null

  is_login: (cb)->
    if @logined == null
      console.log "checking your login status..."
      FB.getLoginStatus (response)=>
        if response.status == 'connected'
          @uid = response.authResponse.userID
          @accessToken = response.authResponse.accessToken
          console.log "You've been logged in."
          @logined = true
          cb(true)
        else if response.status == 'not_authorized'
          console.log "You haven't been logged in yet."
          @logined = false
          cb(false)
        else
          console.log "You haven't been logged in yet."
          @logined = false
          cb(false)
    else
      cb(@logined)

  login: (cb)->
    FB.login (response)=>
      if response.authResponse
        FB.api '/me', (response)=>
          console.log "You've been logged in."
          console.log('Hi, ' + response.name + '.')
          @logined = true
          cb(null)
      else
        @instruct_login(cb)

  permission: (permissions, cb)->
    FB.login((response)=>
      if response.authResponse
        console.log "I've got the permission#{if permissions.length > 1 then 's' else ''}: #{permissions.join(',')}"
        cb()
      else
        console.log "Is anything wrong?"
        cb()
    , {scope: permissions.join(',')}
    )

  instruct_login: (cb)->
    console.log "To start this demo, you should login with Facebook. Type 'login'"
    console.log "(I'm never gonna post anything without asking)"
    cb(null)

