socket = io.connect()
socket.on 'connect', ->
  console.log "connected"

socket.on 'alert', (alert) ->
  console.log "Alert received #{alert}"

socket.on "message", (msg) ->
  console.log "Got a message #{msg.message} from user #{msg.name}"

socket.on "register", (name) ->
  $('.people').append tpl.name({name: name, checked: false})

socket.on 'disconnect', ->
  console.log "disconnected"
	
window.sendMessage = (message) ->
  console.log "sending message #{message}"
  socket.emit 'message', message

window.register = (message) ->
  socket.emit 'register', message
  
  
#Sammy.js configuration stuff - it's like a dispatcher/router thingamabobber
app = $.sammy "#main", () ->
  @get "#!/", (context) ->
    console.log "Got main site with context #{context}"
  @get "#!/login", (context) ->
    console.log "Login screen"
    context.app.swap tpl.login()
$ ->
  app.run "#!/"