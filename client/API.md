PokemonShowdownClient (aka PSC)

# API Reference
- PokemonShowdownClient
- Battle
- ChatRoom
- _Room

## PokemonShowdownClient
### Methods
#### `new PokemonShowdownClient(server: string, loginServer: string)`
Constructs a new `PokemonShowdownClient`.

#### `.socket: WebSocket`
#### `.rooms: {[roomName: string]: Battle | ChatRoom}`
#### `._server: string`
#### `._loginServer: string`
#### `._challstr: string`
#### `._loginRequest(any): any`
#### `._login(options: Object): any`

#### `.connect(): any`
#### `.disconnect(): any`

#### `.login(name: string, password: string): any`

#### `.challenge(name: string, {format: string, room: string}): any`
#### `.respond(accept: Array<string>, reject: Array<string>): any`

#### `.send(message: string, room: string): any`

#### `._handle(data: any): any`
#### `._lex(data: any): any`
#### `._lexLine(line: any, room: any): any`

#### `.on(eventName: string, handler: Function): any`

### Events
#### `'connect'`
#### `'disconnect'`

#### `'ready'`
#### `'login'`

#### `'internal:raw'`
#### `'internal:message'`
#### `'internal:send'`
#### `'internal:updateuser'`

## Battle
### Methods
### Events

## ChatRoom
### Methods
### Events

## _Room
_Room is a superclass for rooms in PSC

### Methods
### Events
