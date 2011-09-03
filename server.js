(function() {
  var app, express, nib, stylus, stylusCompiler;
  express = require('express');
  app = module.exports = express.createServer();
  stylus = require('stylus');
  nib = require('nib');
  stylusCompiler = function(string, path) {
    return stylus(string).set('filename', path).use(nib());
  };
  app.use(stylus.middleware({
    debug: true,
    src: "" + __dirname + "/assets",
    compiler: stylusCompiler
  }));
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
  app.listen(3000);
  console.log("Server listening on port %d in %s mode", app.address().port, app.settings.env);
}).call(this);
