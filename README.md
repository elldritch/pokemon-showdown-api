# pokemon-showdown-api

`pokemon-showdown-api` is a low-level library for connecting to and interacting
with the Pokemon Showdown server.

**This package is under heavy development, and is nowhere near complete.**

## Overview

This package presents a low-level API for interacting with Pokemon Showdown
servers, and tries to avoid making any assumptions about the consumer's goals.
In particular, this API is designed so that _other_ APIs can be built on top of
it (for example, to add logic for handling rooms or battles).

Explicit goals:

1. Don't leak memory over time (this is critical for long-running consumers).
2. Be fast.

(Goal 1 implies that no O(n) logs can be stored, precluding the storing of
messages or rooms. If a consumer needs these features, they should implement
this on their own.)

These lead to two explicit non-goals:

1. No handling logic for rooms.
2. No handling logic for battles.

Instead, this API is built to enable additional libraries to provide such
functionality.

## Usage

To install, run `npm install pokemon-showdown-api`.

(If you want to use a REPL to try and interact with Pokemon Showdown from the
command line, try out `npm install --global pokemon-showdown-api` and use
`pokerepl`.)

In order to instantiate a client, pass the server websocket URL and login server
URL. Both are optional, defaulting to the official Pokemon Showdown servers.

```
var PokeClient = require('pokemon-showdown-api');

var client = new PokeClient();
// By default, this is equivalent to:
// var client = new PokeClient('ws://sim.smogon.com:8000/showdown/websocket', 'https://play.pokemonshowdown.com/action.php');
```

The client will emit events for consumers to listen on. The client does not
store any messages, instead delegating this responsibility to consumers.
(Storing messages uses memory over time, and not all consumers may need this.)

```
client.connect();

// Websocket has connected.
client.on('ready', function() {
  client.login('username', 'password');
});

// Successful login.
client.on('login', function(user) {
  console.log('Logged in as:', user);
});

// A battle challenge from another user has been received.
client.on('challenge', function(user) {
  console.log(user, 'would like to battle!');
});

// Login failed.
client.on('error:login', function(err) {
  console.log('Error encountered while logging in:', err.message);
});
```

In general, any sort of message can be sent using `client.send`. This package
also provides a convenience method authentication using
`client.login(username, password)`.

For more details, see [the API docs](./docs/API.md).

For notes on protocol specifics, see
[Pokemon Showdown Protocol](https://github.com/Zarel/Pokemon-Showdown/blob/master/PROTOCOL.md),
[command parsing source code](https://github.com/Zarel/Pokemon-Showdown-Client/blob/b3ab4374444c52eaf8064353f6b7497ac9e022d4/js/client-chat.js#L341),
and
[socket message parsing source code](https://github.com/Zarel/Pokemon-Showdown-Client/blob/05c89b54d74aca2f39ff7539bffe414d88b610e5/js/client.js#L734).

## Notes about Pokemon Showdown's implementation

Pokemon Showdown is effectively implemented as a fancy chat room. Some of these
are considered regular "chat" rooms, and others are considered "battle" rooms.
Within battle rooms, a battle is conducted by sending special chat messages back
and forth, with the server validating each message.

Authentication occurs by talking to a separate authentication server. The
process is as follows:

1. Get the challenge string (`challstr`) upon connecting to the main server
2. Pass the `challstr` along with a proposed username (and password, if needed)
   to the login server
3. The login server returns an `assertion`, which is passed to the main server
   to prove ownership of a username.
