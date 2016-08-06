# API documentation

**This documentation is not complete.**

## Constructors
```
var PokeClient = require('pokemon-showdown-api');

var client = new PokeClient();
// By default, this is equivalent to:
// var client = new PokeClient('ws://sim.smogon.com:8000/showdown/websocket', 'https://play.pokemonshowdown.com/action.php');
```

## Events
```
// Websocket has connected.
client.on('ready', function() {
  client.login('username', 'password');
});

// Successful login.
client.on('login', function(user) {
  ;
});

// A battle challenge from another user has been received.
client.on('challenge', function() {
  ;
});

client.on('room:joined', function() {
  ;
});
client.on('room:left', function() {
  ;
});

client.on('user:joined', function() {
  ;
});
client.on('user:left', function() {
  ;
});
client.on('user:changed', function() {
  ;
});

client.on('message:chat', function() {
  ;
});
client.on('message:battle', function() {
  ;
});

// Login failed.
client.on('error:login', function(err) {
  ;
});
// Unknown token encountered.
client.on('error:token', function(message) {
  ;
});
```

## Methods
```
client.connect();

client.login('username', 'password');

client.send('message', room);
```
