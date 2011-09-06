socket = io.connect()
socket.on 'connect', ->
  socket.emit 'set name', 'Ed'
  console.log "connected"

socket.on 'alert', (alert) ->
  console.log "Alert received #{alert}"

socket.on "message", (msg) ->
  console.log "Got a message #{msg.message} from user #{msg.name}"

socket.on 'disconnect', ->
  console.log "disconnected"
  
window.sendMessage = (message) ->
  console.log "sending message #{message}"
  socket.emit 'message', message