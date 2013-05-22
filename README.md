# Facebook Client Terminal.
A command line interface (CLI) for facebook.

## Demo
Go to [the emulator running in web browser](http://kissrobber.github.io/facebook_client_terminal/).  
Note: running in REPL mode

## Practical command example
Do you want to have a successful career?  
Add this command to Cron. (automatically like all your boss's status :P)

    node js/cmd.js fql "SELECT status_id FROM status WHERE uid = '#{facebook userid of your boss}' AND NOT(status_id IN (SELECT object_id FROM like WHERE user_id = me() AND object_type = 'status'))" | grep status_id: | awk '{ print $5}' | xargs -I 'status' node js/cmd.js like 'status'
Note: this command doesn't work in the above Demo.

## Usage

### Setup

Copy js/config.json.example to js/config.json and edit this file.

`npm update`

### Run

A Read-Eval-Print-Loop (REPL) mode: `node js/run.js`

Just execute a command: `node js/cmd.js #{a command you like}`  
For example, to get your name `node js/cmd.js api me fields=name | awk '/- name:/{ { for(i=3;i<NF;i++) printf("%s ",$i) } print($NF) }'`

### Essential commands

`home`: get your feed. (synonym for `api me/home`)

`#{object_id}`: get the object.

`post #{your message}:` post your message. (synonym for `api me/feed post #{your message}`)

`like #{object_id}`: like the object. (synonym for `api #{object_id}/likes post`)

`unlike #{object_id}`: unlike the object. (synonym for `api #{object_id}/likes delete`)

`comments #{object_id}`: get the comments of the object to the object. (synonym for `api #{object_id}/comments`)

`comment #{object_id} #{your comment}`: post the comment. (synonym for `api #{object_id}/comments post message=#{your comment}`)

### Low order commands

`api #{object} [method] [params]`: execute the facebook api.

`fql #{fql}`: execute the FQL.

### Misc

*you can use the index in the result list of the previous command instead of the object_id.*  
for example: `like #1` instead of `like 123456789`

### Command examples

get the facebook groups you are in: `api me/groups`

get the feed of the group: `api #{object_id}/feed`

get the messages from your inbox: `api me/inbox`

make an event: `api events post name=#{name of the event}&start_time=#{start time}`

invite your friends to the event: `api #{event_id}/invited/#{user_id} post`

get the event detail: `api #{event_id}`

get the events your are invited to: `api me/events/not_replied`

attend the event: `api #{event_id}/attending post`

get the notifications: `api me/notifications`

search friends by name:

    fql select uid, name from user where uid in (select uid2 from friend where uid1 = me()) and strpos(lower(name), lower('#{a part of name}')) >= 0

get the comments of the object in reverse chronological order: `fql select fromid, username, text from comment where post_id = '#{object_id}' order by time desc`
