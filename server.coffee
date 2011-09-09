#Module Dependencies
express = require 'express'
app = module.exports = express.createServer()
io = require('socket.io').listen app
app.use require('connect-assets')()
jade = require "jade"
fs = require "fs"
jadebrowser = require "jade-browser"

#Configuration
app.set 'views', (__dirname + '/views')
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static(__dirname + '/public')
app.use jadebrowser('/scripts/templates.js', __dirname + '/views', {namespace: "jade", minify: true})

app.configure 'development', ->
  app.use express.errorHandler {dumpExceptions: true, showStack: true}

app.configure 'production', ->
  app.use express.errorHandler()

#Routes to respond to
app.get '/', (req, res) ->
  res.render('index', {title: 'Hello World' })
  
app.get '/template/:file.js', (req, res) ->
  file = "#{__dirname}/views/#{req.params.file}.jade"
  tpl = fs.readFileSync file
  console.log "Template : #{tpl}"
  client = jade.compile tpl, { client: true, debug: true, compileDebug: false, filename: "#{__dirname}/views/#{req.params.file}.jade" }
  res.send "var tpl = window.tpl || {}; tpl.#{file} = #{client}"
  
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
      	#socket.emit "register", "#{name}"
      	socket.broadcast.emit "register", "#{name}"
  
app.listen process.env.PORT || 3000
console.log "Server listening on port %d in %s mode", app.address().port, app.settings.env
