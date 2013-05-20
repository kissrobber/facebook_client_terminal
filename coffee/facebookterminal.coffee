###
 Main
###
class FacebookTerminal
  @version: ->
    '1.0.0'
  @start: ->
    try
      global._us = require("./libs/underscore.js")
      global.FB = require("fb")
      global.FBConnect = new (require("./fbconnect"))

      require("./loginserver.js")

      @apiclient = new Client()

      repl = require("repl")
      repl.start
        prompt: "> "
        input: process.stdin
        output: process.stdout
        eval: @evaluate
        ignoreUndefined: true

      # @apiclient.execute('login')
    catch error
      throw error
    finally
      #process.exit()

  @evaluate: (cmd, context, filename, callback)=>
    cmd = cmd.substr(1, cmd.length - 3)
    if cmd == ''
      callback(null, undefined, cmd)
    else
      value = cmd
      @apiclient.execute(
        cmd
      )
      callback(null, undefined, cmd)

class FBTUtils
  @parse_query: (query)->
    vars = query.split('&')
    rs = {}
    for v in vars
      pair = v.split('=')
      rs[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1])
    rs

  @get_query: (url)->
    url.substr(url.indexOf('?')+1)

  @get_param_from_url: (url, key)->
    @parse_query(@get_query(url))?[key]

class Outputter
  constructor: ->
    @buf = []

  output: (value)=>
    @prepare(value)
    @write()

  write: ->
    @rows = 0
    while(@buf.length > 0)
      @rows++
      @write_next()
    if @buf.length == 0 and @has_next()
      console.log "more...(type 'next')"

  write_next: ->
    console.log @buf.shift()

  has_more: ->
    @buf.length > 0 # or 

  has_next: ->
    !!@paging_next

  prepare: (value)=>
    if value == null or value == undefined
      return

    if value.error?
      @obj_to_output(value)
      error = value.error
      code = error.code
      if code == 10 or (code >= 200 && code <= 299)
        #permission
        permission = _us.last error.message.split(' ')
        @store "Grant me the permission! Type 'permission \#{permission}'"
    else if _us.isArray(value.data) and value.data.length == 0
      @store 'No result. (Is that strange? If so, check the permissions.)'
    else if _us.isObject(value)
      @obj_to_output(value)
    else
      @store value

    if value?.paging?.next
      @paging_next = value?.paging?.next

  obj_to_output: (obj, i)=>
    i = 0 if i == undefined
    for k, v of obj
      @output_kv(k, v, i)

  output_kv:(k, v, i)=>
    if _us.isObject(v)
      @store "#{@indent(i)}#{k}:"
      @obj_to_output(v, 1 + i)
    else
      @store "#{@indent(i)}#{k}: #{v}"

  indent: (i) =>
    rs = ''
    for j in [0..i]
      rs += '- '
    return rs

  store: (v)->
    for t in v.toString().split('\n')
      @buf.push t

class Client
  constructor: ()->
    @history_ids = []
    @command_histories = []
    @pre_result = null
    @re = new RegExp("#[0-9]+")

  is_login: (cb)->
    FBConnect.is_login(cb)

  execute: (cmd)->
    @command_histories.push cmd
    if cmd == 'next'
      if @outputter?.has_more()
        @outputter.write()
      else if @outputter?.has_next()
        @action.next(@cb)
      else
        console.log 'no more'
      return

    @is_login((b)=>
      if b
        try
          cmd = @set_ids(cmd)
          @action = ActionFactory.get_instance(cmd)
          @action.execute(@cb)
        catch error
          if error instanceof CommandError
            #TODO
            console.log 'command error'
          else
            throw error
      else
        switch cmd
          when "login"
            FBConnect.login(@cb)
          else
            FBConnect.instruct_login(@cb)
    )
  
  set_ids:(cmd)->
    @replace_id(cmd)
  replace_id:(cmd)->
    if @re.test(cmd)
      mid = RegExp.lastMatch
      tmp = parseInt(RegExp.lastMatch.substr(1), 10)
      if(@history_ids[tmp])
        mid = @history_ids[tmp]
      return RegExp.leftContext + mid + @replace_id(RegExp.rightContext)
    else
      return cmd

  cb: (rs)=>
    @pre_result = rs
    @outputter = new Outputter()
    @save_ids(rs)

    @outputter.output rs

  save_ids: (rs)->
    if @is_list_data(rs) and rs.data.length > 0 and rs.data[0].id?
      @history_ids = []
      for v in rs.data
        @history_ids.push v.id

  is_list_data:(rs)->
    _us.isObject(rs) and _us.isArray(rs.data)
      
class ActionFactory
  
  @get_instance: (cmd)->
    vs = cmd.split(' ')
    vs = _us.filter vs, (v)-> v.length > 0

    if vs[0] == 'api'
      return new GraphApiAction(vs.slice(1))
    else if vs[0].match(/^\d+_?\d+$/)
      return new GraphApiAction(vs)
    else if vs[0] == 'fql'
      return new FQLAction(cmd)
    else if vs[0] == 'like'
      return new LikeGraphApiAction(vs.slice(1))
    else if vs[0] == 'unlike'
      return new UnlikeGraphApiAction(vs.slice(1))
    else if vs[0] == 'home'
      return new HomeGraphApiAction(vs.slice(1))
    else if vs[0] == 'post'
      return new PostGraphApiAction(vs.slice(1))
    else if vs[0] == 'comment'
      return new CommentGraphApiAction(vs.slice(1))
    else if vs[0] == 'comments'
      return new CommentsGraphApiAction(vs.slice(1))
    else if vs[0] == 'permission'
      return new PermissionAction(vs)
    else if vs[0] == 'login'
      return new NoAction()
    else if vs[0] == 'help'
      return new HelpAction()

    console.log "#{cmd}: command not found"
    new NoAction()

  @is_number_string: (value)->
    _us.every(value.split(''), (v)-> _us.contains([], v))

class CommandError

class Action

  next: ()->
    if @res?.paging?.next?
      utl = FBTUtils.get_param_from_url(@res.paging.next, 'until')
      @fields['until'] = utl
      @execute(@cb)
    else
      console.log 'no more'

class NoAction extends Action
  constructor: (@cmd)->

  execute: (cb)->
    cb(undefined)

class GraphApiAction extends Action
  constructor: (values)->
    if values.length == 0
      throw new CommandError()

    @api = values.shift()
    @method = 'get'
    @fields = {}
    @has_fieds = false

    if values.length > 0
      tmp = values[0]
      if tmp.toLowerCase() == 'post' or tmp.toLowerCase() == 'delete'
        @method = tmp.toLowerCase()
        values.shift()

    if values.length > 0
      tmp = values.shift()
      @fields = FBTUtils.parse_query(tmp)
      if _us.keys(@fields).length > 0
        @has_fieds = true

  execute: (@cb)->
    FB.api(
      @api,
      @method,
      @fields,
      (res)=>
        if res?.paging?.next?
          @res = res
        res = @filter(res)
        @cb(res)
    )

  filter: (res)->
    res

  next: ()->
    if @res?.paging?.next?
      utl = FBTUtils.get_param_from_url(@res.paging.next, 'until')
      @fields['until'] = utl
      @execute(@cb)
    else
      console.log 'no more'

class LikeGraphApiAction extends GraphApiAction
  constructor: (values)->
    if values.length == 0
      throw new CommandError()
    
    @api = "#{values[0]}/likes"
    @method = 'post'
    @fields = {}
    @has_fieds = false

class UnlikeGraphApiAction extends GraphApiAction
  constructor: (values)->
    if values.length == 0
      throw new CommandError()

    @api = "#{values[0]}/likes"
    @method = 'delete'
    @fields = {}
    @has_fieds = false

class HomeGraphApiAction extends GraphApiAction
  constructor: (values)->
    @api = "me/home"
    @method = 'get'
    @fields = {}
    @has_fieds = false
  filter: (obj)=>
    properties = ['privacy', 'type', 'story_tags', 'icon', 'actions', 'status_type', 'with_tags', 'message_tags', 'application', 'properties', 'namespace', 'created_time', 'object_id']
    for k, v of obj
      if _us.contains(properties, k)
        delete obj[k]
      else if(k == 'likes' or k == 'comments' or k == 'shares')
        obj[k] = v.count
      else if(k == 'from')
        obj[k] = "#{v.id}: #{v.name}"
        obj[k] += v.category if v.category?
      else
        if _us.isObject(v)
          @filter(v)
    return obj

class CommentGraphApiAction extends GraphApiAction
  constructor: (values)->
    if values.length != 2
      throw new CommandError()

    @api = "#{values[0]}/comments"
    @method = 'post'
    @fields = {message: values[1]}
    @has_fieds = true

class CommentsGraphApiAction extends GraphApiAction
  constructor: (values)->
    if values.length != 1
      throw new CommandError()

    @api = "#{values[0]}/comments"
    @method = 'get'

class PostGraphApiAction extends GraphApiAction
  constructor: (values)->
    if values.length != 1
      throw new CommandError()

    @api = "me/feed"
    @method = 'post'
    @fields = {message: values[0]}
    @has_fieds = true

class FQLAction extends Action
  constructor: (value)->
    idx = value.indexOf('fql')
    value = value.substr(idx + 4)

    unless value.length > 0
      throw new CommandError()

    @query = value
    console.log @query

  execute: (@cb)->
    FB.api(
      "fql",
      {q:"#{@query}"},
      (res)=>
        @res = res
        @cb(res)
    )

class PermissionAction extends Action
  constructor: (vs)->
    @scope = vs.slice(1)
    unless @scope?.length > 0
      throw new CommandError()
  execute: (@cb)->
    FBConnect.permission(@scope, @cb)

class HelpAction extends Action
  constructor: ()->
  execute: (@cb)->
    console.log "#"
    console.log "# Essential commands"
    console.log "#"
    console.log "home: get your feed. (synonym for 'api me/home')"
    console.log "\#{object_id}: get the object."
    console.log "post \#{your message}: post your message. (synonym for 'api me/feed post \#{your message}')"
    console.log "like \#{object_id}: like the object. (synonym for 'api \#{object_id}/likes post')"
    console.log "unlike \#{object_id}: unlike the object. (synonym for 'api \#{object_id}/likes delete')"
    console.log "comments \#{object_id}: get the comments of the object. (synonym for 'api \#{object_id}/comments')"
    console.log "comment \#{object_id} \#{your comment}: post the comment to the object. (synonym for 'api \#{object_id}/comments post message=\#{your comment}')"
    console.log "#"
    console.log "# Low order commands"
    console.log "#"
    console.log "api \#{object} [method] [params]: execute the facebook api."
    console.log "fql \#{fql}: execute the FQL."
    console.log "#"
    console.log "# you can use the index in the result list of the previous command instead of the object_id."
    console.log "# For more details, go to https://github.com/kissrobber/facebook_client_terminal"
    console.log "#"
    @cb()

#BUG
#likes の next

#TODO
# Script in WebStrage
#like {省略}
# setAccessToken cmd https://developers.facebook.com/tools/access_token/
  

module.exports = FacebookTerminal;
