# PokemonShowdownClient

PokemonShowdownClient (abbreviated PSC) is a high-level library for connecting
to and interacting with the Pokemon Showdown server.

## Overview

The design goals for PSC are as follows:

1. Explicit support for battling.
2. A high level interface, with concepts of "turns" and "battles".
3. Fast code.
4. Good testability.

The code is organised around a high-level concept of a Client, which represents the actions of a single user. This user can create rooms, which are divided into battles and chat rooms. Actions that users would normally perform globally (e.g. renaming themselves, sending or receiving challenges, etc.) are delegated to the client, while room-specific actions (e.g. picking a move in a battle) are delegated to the specific room.

## Usage

To install, run `npm install pokemon-showdown-client`.

## Internals

When the client receives a message from the server, it calls its `_handle` method, which lexes the message into an internal representation known as a `Message`. If these messages are room-specific, it passes the `Message` to the `_handle` method of the appropriate room. Both the client and its rooms signal events by inheriting from `EventEmitter`.

## Roadmap
### Blocking
- [ ] Room-specific event handling
- [ ] Events for battle functionality
- [ ] Improved documentation

### Non-blocking
- [ ] Promise-based return values that fulfil when a command has been
  confirmed
- [ ] "Raw" mode for REPL that emits JSON events on stdout so it can embedded into other programs

### Wishlist
- [ ] [Flow](flowtype.org) typechecking
- [ ] Use a proper lexer/parser pipeline
