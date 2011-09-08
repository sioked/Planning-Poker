socket = io.connect()
socket.on 'connect', ->
  console.log "connected"

socket.on 'alert', (alert) ->
  console.log "Alert received #{alert}"

socket.on "message", (msg) ->
  console.log "Got a message #{msg.message} from user #{msg.name}"

socket.on "register", (msg) ->
  $('.people').append("<div class='name'>#{msg}</div>")

socket.on 'disconnect', ->
  console.log "disconnected"
	
window.sendMessage = (message) ->
  console.log "sending message #{message}"
  socket.emit 'message', message

window.register = (message) ->
  socket.emit 'register', message