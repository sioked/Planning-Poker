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
  
io.sockets.on 'connection', (socket) ->
  socket.on 'message', (msg) ->
    socket.get 'name', (err, name) ->
      if !err
        socket.broadcast.emit "message", { name: "#{name}", message: "#{msg}"}
      else
        socket.emit "alert", "You are not registered."
  socket.on 'register', (name) ->
	  console.log "registering #{name}"
	  socket.set 'name', name, ->
      console.log "sending message back to #{name}"
      socket.emit "alert", "#{name} is ready for action"
      socket.broadcast.emit "alert", "Welcome #{name}"
      socket.broadcast.emit "register", name
      socket.emit "register", name
  
app.listen process.env.PORT || 3000
console.log "Server listening on port %d in %s mode", app.address().port, app.settings.env
