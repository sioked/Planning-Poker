#Module Dependencies
express = require 'express'
app = module.exports = express.createServer()
io = require('socket.io').listen app
app.use require('connect-assets')()
jade = require "jade"
fs = require "fs"

#Configuration
app.set 'views', (__dirname + '/views')
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static(__dirname + '/public')

dir = "#{__dirname}/views"
templates = "window.tpl = {};"
fs.readdir dir, (err, files) ->
  files.forEach (file) ->
    filename = "#{dir}/#{file}"
    nm = /(.*)\.jade$/.exec(file)[1]
    tpl = fs.readFileSync filename
    fn = jade.compile tpl, {client: true, debug: true, compileDebug: false, filename:filename}
    templates += "tpl.#{nm} = #{fn};"

app.configure 'development', ->
  app.use express.errorHandler {dumpExceptions: true, showStack: true}

app.configure 'production', ->
  app.use express.errorHandler()

#Routes to respond to
app.get '/', (req, res) ->
  res.render('index', {title: 'Hello World' })

app.get '/scripts/templates.js', (req, res) ->
  res.header "Content-Type", "application/javascript"
  res.send templates
  
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
