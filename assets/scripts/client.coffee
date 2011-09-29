#Sammy.js configuration stuff - it's like a dispatcher/router thingamabobber
app = $.sammy "#main", () ->
  @get "#!/", (context) =>
    console.log "Got main site with context #{context}"
    id = $.cookie("id")
    if not id
      console.log "no id"
      app.setLocation "#!/login"
    else
      console.log "Joining"
      join id, ->
        console.log "Joined!"
        context.app.swap tpl.cards()
        $("a.card").bind "click", ->
          $(".active").removeClass 'active'
          $(@).addClass 'active'
          val = $(this).data "vote"
          vote(val)
      
  @get "#!/login", (context) =>
    console.log "Login screen"
    context.app.swap tpl.login()
    $("#login").bind "submit", (event) ->
      nm = $("#login input").val()
      register nm, (id) ->
        console.log "Got an id #{id}"
        $.cookie("id", id);
        app.setLocation "#!/"
      false  
  
  @get "#!/results", (context) =>
    console.log "Results screen"
    $.get "/results", (results) ->
      context.app.swap tpl.allresults({results: results})
      
  @get "#!/reset", (context) =>
    console.log "resetting"
    reset()
      
$ ->
  #Start the app!
  app.run "#!/"

socket = io.connect()
socket.on 'connect', ->
  console.log "connected"

socket.on 'alert', (alert) ->
  console.log "Alert received #{alert}"

socket.on "message", (msg) ->
  console.log "Got a message #{msg.message} from user #{msg.name}"

socket.on "newUser", (user) ->
  if not $(".name-#{user.id}")[0]
    $('.people').append tpl.name({name: user.name, checked: false, id: user.id, vote: user.vote})

socket.on "vote", (user) ->
  $('.icon', $('.name-'+user.id)).addClass('check')
  
socket.on "remove", (users) ->
  id = $.cookie "id"
  if (user for user in users when user.id = id)[0]
    join id
  $('.name-'+user.id).remove() for user in users
    
socket.on "reset", (users) ->
  for user in users 
    $('.icon', $('.name-'+user.id)).removeClass('check')
  # need to remove the votes here.
  console.log "results: " + $('.results.result')
  $('.results.result').remove()
  app.setLocation "#!/"
  
socket.on "allUsers", (users) ->
  $('.people').empty()
  for user in users 
    $('.people').append tpl.name({name: user.name, checked: user.vote == true, id: user.id, vote: user.vote})

socket.on "results", (results) ->
  console.log "Got results"
  app.setLocation "#!/results"
      
socket.on 'disconnect', ->
  console.log "disconnected"
	
window.sendMessage = (message) ->
  socket.emit 'message', message

window.register = (message, callback) ->
  socket.emit 'register', message
  socket.on "registered", (msg) ->
    callback?(msg)

window.join = (id, callback) ->
  socket.emit "join", id
  socket.on "joined", (msg)->
    if(!msg)
      console.log "Got an error on join"
      console.log err
      $.cookie("id", null)
      app.setLocation "#!/login"
    else
      console.log "Calling callback"
      callback?()

window.vote = (message) ->
  socket.emit 'vote', message

window.reset = () ->
  socket.emit 'reset'