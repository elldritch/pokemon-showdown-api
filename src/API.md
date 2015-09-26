# API Reference
In general, identifiers prefixed with `_` are intended to be private, and others are public.

- PokemonShowdownClient
- Battle
- ChatRoom
- _Room

## PokemonShowdownClient extends EventEmitter
### Properties
#### `.socket: WebSocket`
#### `.rooms: {[roomName: string]: Battle | ChatRoom}`
#### `._server: string`
#### `._loginServer: string`
#### `._challstr: string`
#### `._loginRequest(any): any`
#### `._login(options: Object): any`

#### `PokemonShowdownClient.MESSAGE_TYPES: {[messageType: string]: Symbol}`

### Methods
#### `new PokemonShowdownClient(server: string, loginServer: string)`
Constructs a new `PokemonShowdownClient`.

#### `.connect(): any`
#### `.disconnect(): any`

#### `.login(name: string, password: string): any`

#### `.challenge(name: string, {format: string, room: string}): any`
#### `.respond(accept: Array<string>, reject: Array<string>): any`

#### `.send(message: string, room: string): any`

#### `._handle(data: string): any`
#### Messages
`type Message = {type: Symbol, data: Object, room: string}`

#### `._lex(data: string): Array<Message>`
#### `._lexLine(line: string, room: string): Message`

#### `.on(eventName: string, handler: Function): any` using `EventEmitter`

### Events
#### `'connect'`
#### `'disconnect'`

#### `'ready'`
#### `'login'`

#### `'internal:raw'`
#### `'internal:message'`
#### `'internal:send'`
#### `'internal:updateuser'`

## Battle extends _Room
### Properties
#### `.players: {[playerPosition: string]: string}`
#### `.rated: boolean`
#### `.gametype: Symbol`
#### `.gen: number`
#### `.tier: string`
#### `.rules: Array<{name: string, description: string}>`

#### `Battle.GAME_TYPES: {[gameType: string]: Symbol}`

### Methods
#### `new Battle()`
#### `._handle(message: Message): any` overriding `_Room`

### Events

## ChatRoom extends _Room
### Properties
#### `.users: Array<string>`
#### `.messages: Array<Message>`

### Methods
#### `new ChatRoom()`
#### `._handle(message: Message): any` overriding `_Room`

### Events

## _Room
_Room is a superclass for rooms in PSC. It provides base functionality for recording raw incoming messages.

### Properties
#### `._messages: Array<Message>`

### Methods
#### `new _Room()`
#### `._handle(message: Message): any`

### Events
