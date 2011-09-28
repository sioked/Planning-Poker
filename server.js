(function() {
  var app, areUsersFinished, calculateResults, client, express, findUser, findUsers, io, redis;
  express = require('express');
  app = module.exports = express.createServer();
  io = require('socket.io').listen(app);
  redis = require('redis');
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(require('connect-assets')());
  app.use(require('jade-client-connect')("" + __dirname + "/views"));
  app.use(express.static(__dirname + '/public'));
  client = redis.createClient();
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
      title: 'Planning Poker'
    });
  });
  app.get('/results', function(req, res) {
    res.contentType('application/json');
    return res.send(JSON.stringify(calculateResults()));
  });
  findUsers = function(callback) {
    var allUsers;
    allUsers = [];
    client = redis.createClient();
    return client.smembers("users", function(err, users) {
      var user, _i, _len;
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        user = users[_i];
        client.hgetall(user, function(err, u) {
          return allUsers.push(u);
        });
      }
      if (callback) {
        return callback(allUsers);
      }
    });
  };
  findUser = function(id, callback) {
    return client.hgetall("user:" + id, function(err, result) {
      return callback(result);
    });
  };
  areUsersFinished = function(users) {
    var user, _i, _len;
    if (users) {
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        user = users[_i];
        if (user.vote <= 0) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  };
  calculateResults = function(users) {
    var user, v, vote, votes, _i, _len;
    votes = [];
    for (_i = 0, _len = users.length; _i < _len; _i++) {
      user = users[_i];
      if (user.vote > 0) {
        vote = (function() {
          var _j, _len2, _results;
          _results = [];
          for (_j = 0, _len2 = votes.length; _j < _len2; _j++) {
            v = votes[_j];
            if (user.vote === v.vote) {
              _results.push(v);
            }
          }
          return _results;
        })();
        if (vote.length > 0) {
          vote[0].count += 1;
          vote[0].users.push(user);
        } else {
          votes.push({
            vote: user.vote,
            count: 1,
            users: [user]
          });
        }
      }
    }
    return votes;
  };
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
    socket.on('register', function(name) {
      client = redis.createClient();
      return client.incr("id", function(err, result) {
        console.log("New Id: " + result);
        return socket.set('id', result, function() {
          var user;
          user = {
            id: result,
            name: name,
            vote: 0
          };
          return client.sadd("users", "user:" + result, function(err, result) {
            return client.hmset("user:" + result, "name", name, "vote", 0, function(err, result) {
              return findUsers(function(users) {
                socket.emit("allUsers", users);
                socket.emit("registered", result);
                return socket.broadcast.emit("register", user);
              });
            });
          });
        });
      });
    });
    socket.on('vote', function(vote) {
      return socket.get('id', function(err, id) {
        var allUsers;
        if (!err) {
          allUsers = [];
          return client.hmset("user:" + id, "vote", vote, function(err, result) {
            var user;
            return user = findUser(id, function(user) {
              if (user) {
                socket.broadcast.emit("vote", user);
                socket.emit("vote", user);
                return findUsers(function(users) {
                  var results, user, _i, _len;
                  console.log(users);
                  for (_i = 0, _len = users.length; _i < _len; _i++) {
                    user = users[_i];
                    console.log(user);
                  }
                  if (areUsersFinished(users)) {
                    results = calculateResults(users);
                    socket.emit("results", results);
                    return socket.broadcast.emit("results", results);
                  }
                });
              }
            });
          });
        } else {
          return socket.emit("alert", "You are not registered");
        }
      });
    });
    socket.on('reset', function(reset) {
      var user, _i, _len;
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        user = users[_i];
        user.vote = 0;
      }
      socket.broadcast.emit("reset", users);
      return socket.emit("reset", users);
    });
    return socket.on('disconnect', function() {
      return socket.get('id', function(err, id) {
        return findUsers(function(users) {
          var removals, user;
          removals = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = users.length; _i < _len; _i++) {
              user = users[_i];
              if (user.id === id) {
                _results.push(user);
              }
            }
            return _results;
          })();
          users = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = users.length; _i < _len; _i++) {
              user = users[_i];
              if (user.id !== id) {
                _results.push(user);
              }
            }
            return _results;
          })();
          return socket.broadcast.emit("remove", removals);
        });
      });
    });
  });
  app.listen(process.env.PORT || 3000);
  console.log("Server listening on port %d in %s mode", app.address().port, app.settings.env);
}).call(this);
