###
 http server for facebook login
###
express = require('express')
passport = require('passport')
FBStrategy = require('passport-facebook').Strategy
config = require('./config.json')
fs = require('fs')

console.log('Server for facebook login is booting...')
app = express();

passport.serializeUser (user, done)->
  done(null, user)

passport.deserializeUser (obj, done)->
  done(null, obj)

passport.use new FBStrategy {
    clientID: config.fb_app_id
    clientSecret: config.fb_app_secret
    callbackURL: "http://#{config.http_server_host}:#{config.http_server_port}/auth/facebook/callback"
  },
  (accessToken, refreshToken, user, done)->
    console.log "You've logged in."
    console.log "accessToken: #{accessToken}"
    fs.writeFile('access_token.txt', accessToken, (err)->
      throw err if err?
    )
    FBConnect.set_access_token accessToken
    return done(null, user)

app.configure ()->
  #app.use(express.logger())
  app.use(passport.initialize())
  app.use(app.router)

app.get '/', (req, res)->
  msg = ''
  unless req.query.logined == undefined
    msg = 'Logined.' 
  unless req.query.failed == undefined
    msg = 'Login failed.'
  res.send(
    "<html>
    <body style='background-color: #111; color: #bbb;'>
    #{msg}<br/>
    <a href='/auth/facebook'>login</a>
    </body>
    </html>"
    )

app.get '/auth/facebook',
  passport.authenticate('facebook', scope: ['read_stream', 'publish_stream', 'email', 'read_friendlists', 'read_insights', 'read_mailbox', 'read_requests', 'xmpp_login', 'ads_management', 'create_event', 'manage_friendlists', 'manage_notifications', 'user_online_presence', 'friends_online_presence', 'publish_actions', 'rsvp_event', 'user_about_me', 'friends_about_me', 'user_activities', 'friends_activities', 'user_birthday', 'friends_birthday', 'user_checkins', 'friends_checkins', 'user_education_history', 'friends_education_history', 'user_events', 'friends_events', 'user_groups', 'friends_groups', 'user_hometown', 'friends_hometown', 'user_interests', 'friends_interests', 'user_likes', 'friends_likes', 'user_location', 'friends_location', 'user_notes', 'friends_notes', 'user_photos', 'friends_photos', 'user_questions', 'friends_questions', 'user_relationships', 'friends_relationships', 'user_relationship_details', 'friends_relationship_details', 'user_religion_politics', 'friends_religion_politics', 'user_status', 'friends_status', 'user_subscriptions', 'friends_subscriptions', 'user_videos', 'friends_videos', 'user_website', 'friends_website', 'user_work_history', 'friends_work_history'])

app.get '/auth/facebook/callback',
  passport.authenticate('facebook',
    {
      failureRedirect: '/?failed'
    })
  ,(req, res)->
    res.redirect('/?logined')

app.listen(1337);
console.log('Server running at http://127.0.0.1:1337/')
