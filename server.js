(function() {
  var app, dir, express, fs, io, jade, templates;
  express = require('express');
  app = module.exports = express.createServer();
  io = require('socket.io').listen(app);
  app.use(require('connect-assets')());
  jade = require("jade");
  fs = require("fs");
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
  dir = "" + __dirname + "/views";
  templates = "window.tpl = {};";
  fs.readdir(dir, function(err, files) {
    return files.forEach(function(file) {
      var filename, fn, nm, tpl;
      filename = "" + dir + "/" + file;
      nm = /(.*)\.jade$/.match(file);
      tpl = fs.readFileSync(filename);
      fn = jade.compile(tpl, {
        client: true,
        debug: true,
        compileDebug: false,
        filename: filename
      });
      return templates += "tpl." + nm + " = " + fn + ";";
    });
  });
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
  app.get('/scripts/templates.js', function(req, res) {
    res.header("Content-Type", "application/javascript");
    return res.send(templates);
  });
  app.get('/template/:file.js', function(req, res) {
    var client, file, tpl;
    file = "" + __dirname + "/views/" + req.params.file + ".jade";
    tpl = fs.readFileSync(file);
    console.log("Template : " + tpl);
    client = jade.compile(tpl, {
      client: true,
      debug: true,
      compileDebug: false,
      filename: "" + __dirname + "/views/" + req.params.file + ".jade"
    });
    return res.send("var tpl = window.tpl || {}; tpl." + file + " = " + client);
  });
  io.sockets.on('connection', function(socket) {
    socket.on('message', function(msg) {
      return socket.get('name', function(err, name) {
        if (!err) {
          return socket.broadcast.emit("message", {
            name: "" + name,
            message: "" + msg
          });
        } else {
          return socket.emit("alert", "You are not registered.");
        }
      });
    });
    return socket.on('register', function(name) {
      console.log("registering " + name);
      return socket.set('name', name, function() {
        console.log("sending message back to " + name);
        return socket.broadcast.emit("register", "" + name);
      });
    });
  });
  app.listen(process.env.PORT || 3000);
  console.log("Server listening on port %d in %s mode", app.address().port, app.settings.env);
}).call(this);
