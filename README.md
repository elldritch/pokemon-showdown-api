# PokemonShowdownClient

PokemonShowdownClient (abbreviated PSC) is a high-level library for connecting
to and interacting with the Pokemon Showdown server.

## Overview

The design goals for PSC were as follows:

1. Explicit support for battling.
2. A high level interface, with concepts of "turns" and "battles".
3. Fast code.
4. Good testability.

The code is organised around a high-level concept of a`PokemonShowdownClient`, which represents the actions of a single user. This user can create `_Room`s, which are divided into `Battle`s and `ChatRoom`s. Actions that users would normally perform globally (e.g. renaming themselves, sending or receiving challenges, etc.) are delegated to the client, while room-specific actions (e.g. picking a move in a battle) are delegated to the specific room.

## Usage

To install, run `npm install pokemon-showdown-client`.

## Internals

When the client receives a message from the server, it calls its `_handle` method, which lexes the message into an internal representation known as a `Message`. If these messages are room-specific, it passes the `Message` to the `_handle` method of the appropriate room. Both the client and its rooms signal events by inheriting from `EventEmitter`.

## TODO
### Blocking
- [ ] Events for battle functionality
- [ ] Improved documentation

### Non-blocking
- [ ] Flow typechecking for CoffeeScript code
- [ ] Promise-based return values that fulfil when a command has been
  confirmed
