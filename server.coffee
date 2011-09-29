#Module Dependencies
express = require 'express'
app = module.exports = express.createServer()
io = require('socket.io').listen app

#Configuration
app.set 'views', (__dirname + '/views')
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use require('connect-assets')()
app.use require('jade-client-connect')("#{__dirname}/views")
app.use express.static(__dirname + '/public')

#Collection of users
registered = []
users      = []

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

#list of ids
ids = [1000..1]

findUser = (id) ->
  for user in users
    if(user.id == id) 
      return user
  return null
  
areUsersFinished = () ->
  console.log users
  for user in users
    if user.vote <= 0
      return false
  return true

calculateResults = () ->
  votes = []
  for user in users when user.vote >0 
    vote = (v for v in votes when user.vote == v.vote)
    if(vote.length > 0)
      vote[0].count+=1
      vote[0].users.push user
    else
      votes.push {vote: user.vote, count: 1, users: [user]}
  return votes  
  
clients = []
sockets = []
io.sockets.on 'connection', (socket) ->
  
  socket.on 'message', (msg) ->
    socket.get 'name', (err, name) ->
      if !err
        socket.broadcast.emit "message", { name: "#{name}", message: "#{msg}"}
      else
        socket.emit "alert", "You are not registered."
        
  socket.on 'register', (name) ->
    id = (user.id for user in registered when user.name is name)[0]
    console.log "Got an id #{id}"
    if not id
      id=ids.pop()
      console.log socket
      registered.push 
        id    : id
        name  : name
        socket: socket.id
      sockets.push
        id    : socket.id
        socket: socket
    console.log registered
    socket.set 'id', id, ->
      console.log "id: #{id}"
      socket.emit "registered", id
      
  socket.on 'join', (id) ->
    id = id * 1
    console.log "got a join"
    console.log users
    if (user for user in users when user.id is id)[0]
      console.log "Already in here!"
      old_socket = (ruser.socket for ruser in registered when user.id is id)[0]
      #console.log sockets[old_socket]
      #socket.manager.onClientDisconnect( old_socket ) #Kick out any old sockets
      socket.set 'id', id, ->
        socket.emit "joined", id
        socket.emit "allUsers", users
        socket.broadcast.emit "newUser", user
    else
      console.log registered
      console.log "Id search is #{id}"
      name = (user.name for user in registered when user.id is id)[0]
      console.log name
      users.push
        id    : id
        name  : name
        vote  : 0
      socket.emit "allUsers", users
      console.log "All done, replying with a joined"
      socket.emit "joined", id
      socket.broadcast.emit "newUser", user
      
  socket.on 'vote', (vote) ->
    socket.get 'id', (err, id) ->
      if !err
        user = findUser(id)
        if user
          user.vote = vote
          socket.broadcast.emit "vote", user
          socket.emit "vote", user
          if areUsersFinished()
            results = calculateResults()
            socket.emit "results", results
            socket.broadcast.emit "results", results
      else
        socket.emit "alert", "You are not registered"
        
  socket.on 'reset', (reset) ->
    user.vote = 0 for user in users
    socket.broadcast.emit "reset", users
    socket.emit "reset", users
    
  socket.on 'disconnect', -> 
    socket.get 'id', (err,id) ->
      removals = (user for user in users when user.id == id)
      users = (user for user in users when user.id != id)
      socket.broadcast.emit "remove", removals
    
app.listen process.env.PORT || 3000
console.log "Server listening on port %d in %s mode", app.address().port, app.settings.env
