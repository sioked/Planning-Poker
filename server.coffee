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

app.configure 'development', ->
  app.use express.errorHandler {dumpExceptions: true, showStack: true}

app.configure 'production', ->
  app.use express.errorHandler()

#Routes to respond to
app.get '/', (req, res) ->
  res.render('index', {title: 'Planning Poker' })
  
#Collection of users
users =[]
#list of ids
ids = [1000..1]

findUser = (id) ->
  for user in users
    if(user.id == id) 
      return user
  return null
  
io.sockets.on 'connection', (socket) ->
  socket.on 'message', (msg) ->
    socket.get 'name', (err, name) ->
      if !err
        socket.broadcast.emit "message", { name: "#{name}", message: "#{msg}"}
      else
        socket.emit "alert", "You are not registered."
        
  socket.on 'register', (name) ->
    id=ids.pop()
    socket.set 'id', id, ->
      user = {id: id, name: name, vote: 0}
      users.push user
      socket.emit "allUsers", users
      socket.broadcast.emit "register", user
      
  socket.on 'vote', (vote) ->
    socket.get 'id', (err, id) ->
      if !err
        user = findUser(id)
        if user
          user.vote = vote
          socket.broadcast.emit "vote", user
          socket.emit "vote", user
      else
        socket.emit "alert", "You are not registered"
        
  socket.on 'reset', (reset) ->
    user.vote = 0 for user in users
    socket.broadcast.emit "reset", users
    socket.emit "reset", users
    
app.listen process.env.PORT || 3000
console.log "Server listening on port %d in %s mode", app.address().port, app.settings.env
