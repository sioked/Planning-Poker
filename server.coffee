#Module Dependencies
express = require 'express'
app = module.exports = express.createServer()
io = require('socket.io').listen app
redis = require('redis')

#Configuration
app.set 'views', (__dirname + '/views')
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use require('connect-assets')()
app.use require('jade-client-connect')("#{__dirname}/views")
app.use express.static(__dirname + '/public')

#IDs
client = redis.createClient()
#client.set("id", 10)
  
app.configure 'development', ->
  app.use express.errorHandler {dumpExceptions: true, showStack: true}

app.configure 'production', ->
  app.use express.errorHandler()

#Routes to respond to
app.get '/', (req, res) ->
  res.render('index', {title: 'Planning Poker' })
  
app.get '/results', (req, res) ->
  res.contentType 'application/json'
  res.send JSON.stringify(calculateResults())

#Collection of users
#users = []
findUsers = (callback) ->
  client.smembers "users", (err, users) ->
    allUsers = []
    for user, index in users 
      client.hgetall user, (err, u) ->
        allUsers.push u
        console.log "user in findusers: #{u}"
        console.log "index: #{index}"
        console.log "users size: #{users.length}"
        if index == (users.length)
          console.log "allUsers in findusers: "
          console.log allUsers
          callback?(allUsers)
  return null
    
findUser = (id, callback) ->
  client.hgetall "user:#{id}", (err, result) ->
    callback(result)
  
#probably should just pass in list of users
areUsersFinished = (users) ->
  if(users)
    for user in users
      if user.vote <= 0
        return false
    return true
  else
    return false

calculateResults = (users) ->
  votes = []
  for user in users when user.vote >0 
    vote = (v for v in votes when user.vote == v.vote)
    if(vote.length > 0)
      vote[0].count+=1
      vote[0].users.push user
    else
      votes.push {vote: user.vote, count: 1, users: [user]}
  return votes  
  
io.sockets.on 'connection', (socket) ->
  socket.on 'message', (msg) ->
    socket.get 'name', (err, name) ->
      if !err
        socket.broadcast.emit "message", { name: "#{name}", message: "#{msg}"}
      else
        socket.emit "alert", "You are not registered."
        
  socket.on 'register', (name) ->
    client.incr "id", (err, id) ->
      socket.set 'id', id, ->
        user = {id: id, name: name, vote: 0}
        client.sadd "users", "user:#{id}", (err, addResult) ->
          client.hmset "user:#{id}", "name", name, "vote", 0, (err, result) ->
            findUsers (users) ->
              console.log users
              socket.emit "allUsers", users
              console.log "id: #{id}"
              socket.emit "registered", id
              console.log("user: #{user}")
              socket.broadcast.emit "register", user
      
  socket.on 'vote', (vote) ->
    socket.get 'id', (err, id) ->
      if !err
        allUsers = []
        client.hmset "user:#{id}", "vote", vote, (err, result) ->
          user = findUser id, (user) ->
            if user
              socket.broadcast.emit "vote", user
              socket.emit "vote", user
              findUsers (users) ->
                console.log "all users: #{users}"
                console.log "user: #{user}" for user in users
                if(areUsersFinished(users))
                  results = calculateResults(users)
                  socket.emit "results", results
                  socket.broadcast.emit "results", results
      else
        socket.emit "alert", "You are not registered"
        
  socket.on 'reset', (reset) ->
    user.vote = 0 for user in users
    socket.broadcast.emit "reset", users
    socket.emit "reset", users
    
  #need to rethink this for redis
  socket.on 'disconnect', -> 
    socket.get 'id', (err,id) ->
      findUsers (users) ->
        removals = (user for user in users when user.id == id)
        users = (user for user in users when user.id != id)
        socket.broadcast.emit "remove", removals
    
app.listen process.env.PORT || 3000
console.log "Server listening on port %d in %s mode", app.address().port, app.settings.env
