#Planning Poker

This application will allow a project team to play planning poker while
planning tasks to include in a forthcoming sprint.

##Technologies Used
* [CoffeeScript](http://jashkenas.github.com/coffee-script/)
* [Node.js](http://nodejs.org)
* [Express](http://expressjs.com/)
* [Jade Templating](http://jade-lang.com/)
* [Stylus
  Stylesheets](http://learnboost.github.com/stylus/docs/middleware.html)
* [Socket.io](http://socket.io)
# [Redis](http://redis.io)

##Setup & Run Project

```
#Assuming both Node and NPM are installed
#Install CoffeeScript globally so that you can run the project
npm install -g coffee-script
npm install -d
coffee server.coffee
```
##Heroku
If you want to push this to Heroku, you will need to install redis there.
```
heroku addons:add redistogo
```

##License
This project is licensed under the MIT license. Please see the license for more details.
