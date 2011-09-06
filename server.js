(function() {
  var app, express, io;
  express = require('express');
  app = module.exports = express.createServer();
  io = require('socket.io').listen(app);
  app.use(require('connect-assets')());
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
  app.configure('development', function() {
    return app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
  });
  app.configure('production', function() {
    return app.use(express.errorHandler());
  });
  app.get('/', function(req, res) {
    return res.render('index', {
      title: 'Hello World'
    });
  });
  io.sockets.on('connection', function(socket) {
    socket.on('set name', function(name) {
      console.log("got a name request for " + name);
      return socket.set('name', name, function() {
        console.log("sending message back to " + name);
        socket.emit("alert", "" + name + " is ready for action");
        return socket.broadcast.emit("alert", "Welcome " + name);
      });
    });
    return socket.on('message', function(msg) {
      return socket.get('name', function(err, name) {
        if (!err) {
          return socket.broadcast.emit("message", {
            name: "" + name,
            message: "" + msg
          });
        }
      });
    });
  });
  app.listen(process.env.PORT || 3000);
  console.log("Server listening on port %d in %s mode", app.address().port, app.settings.env);
}).call(this);
