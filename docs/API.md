# API documentation

**This documentation is not complete.**

Types are documented using [Flow](https://flowtype.org/docs). Most notation
should be intuitive. Some useful pointers:

1. [`?T`](https://flowtype.org/docs/nullable-types.html#_) indicates a
   nullable/optional `T` (or an
   [optional argument](https://flowtype.org/docs/functions.html#variadics) when
   used in a function signature)
2. [`void`](https://flowtype.org/docs/builtins.html#null-and-void) is the type
   of `undefined`, distinct from `null` (the type of `null`)
3. [`A & B`](https://flowtype.org/docs/objects.html#reusable-object-types) is an
   [intersection type](https://flowtype.org/docs/union-intersection-types.html#_):
   it is an object fulfilling both the requirements of `A` as well as `B`
4. We define our own `integer` primitive type to be a `number` which only takes
   on integer values

Pokemon Showdown uses distinct servers at distinct URLs for the actual chat
server and for authentication. The former is referred to as the "main server",
and the latter is the "auth server".

## Constructors

### `PokeClient: (mainUrl: ?string, authUrl: ?string) => PokeClient`

## Data structures

### `type RoomId = string`
### `type UserId = string`
### `type Avatar = integer`
Most IDs can be treated as primitives. A user's `UserId` is the same as their
username.

### `type Message = BaseMessage | StringMessage | DataMessage`
### `type BaseMessage = {type: MessageType}`
### `type StringMessage = BaseMessage & {data: string}`
### `type DataMessage = BaseMessage & {data: Object}`
Most events return `Message`s. These consist of a `type` field, which is one of
the symbols in `PokeClient.MESSAGE_TYPES`, and a `data` field, which is either a
`string` or `Object` depending on the message.

(Technically, it's always an `Object` because a `string` is an `Object`, but
that's not important.)

### `type MessageType = Symbol`
These types correspond roughly to the events emitted by `PokeClient`. A full
list of these types can be found in [symbols.coffee](../src/symbols.coffee).

```
OTHER.TOURNAMENT
OTHER.UNKNOWN

ROOM_INIT.INIT
ROOM_INIT.DEINIT
ROOM_INIT.TITLE
ROOM_INIT.USERS

ROOM_MESSAGES.MESSAGE
ROOM_MESSAGES.HTML
ROOM_MESSAGES.UHTML
ROOM_MESSAGES.UHTMLCHANGE
ROOM_MESSAGES.JOIN
ROOM_MESSAGES.LEAVE
ROOM_MESSAGES.NAME
ROOM_MESSAGES.CHAT
ROOM_MESSAGES.CHAT_TIMESTAMP
ROOM_MESSAGES.TIMESTAMP
ROOM_MESSAGES.BATTLE
ROOM_MESSAGES.RAW

BATTLE.PLAYER
BATTLE.GAMETYPE
BATTLE.GEN
BATTLE.TIER
BATTLE.RATED
BATTLE.RULE
BATTLE.CLEARPOKE
BATTLE.POKE
BATTLE.TEAMPREVIEW
BATTLE.REQUEST
BATTLE.INACTIVE
BATTLE.INACTIVEOFF
BATTLE.START
BATTLE.WIN
BATTLE.TIE

BATTLE.ACTIONS.MAJOR.MOVE
BATTLE.ACTIONS.MAJOR.SWITCH
BATTLE.ACTIONS.MAJOR.DRAG
BATTLE.ACTIONS.MAJOR.SWAP
BATTLE.ACTIONS.MAJOR.DETAILSCHANGE
BATTLE.ACTIONS.MAJOR.CANT
BATTLE.ACTIONS.MAJOR.FAINT
BATTLE.ACTIONS.MINOR.FAIL
BATTLE.ACTIONS.MINOR.DAMAGE
BATTLE.ACTIONS.MINOR.HEAL
BATTLE.ACTIONS.MINOR.STATUS
BATTLE.ACTIONS.MINOR.CURESTATUS
BATTLE.ACTIONS.MINOR.CURETEAM
BATTLE.ACTIONS.MINOR.BOOST
BATTLE.ACTIONS.MINOR.UNBOOST
BATTLE.ACTIONS.MINOR.WEATHER
BATTLE.ACTIONS.MINOR.FIELDSTART
BATTLE.ACTIONS.MINOR.FIELDEND
BATTLE.ACTIONS.MINOR.SIDESTART
BATTLE.ACTIONS.MINOR.SIDEEND
BATTLE.ACTIONS.MINOR.CRIT
BATTLE.ACTIONS.MINOR.SUPEREFFECTIVE
BATTLE.ACTIONS.MINOR.RESISTED
BATTLE.ACTIONS.MINOR.IMMUNE
BATTLE.ACTIONS.MINOR.ITEM
BATTLE.ACTIONS.MINOR.ENDITEM
BATTLE.ACTIONS.MINOR.ABILITY
BATTLE.ACTIONS.MINOR.ENDABILITY
BATTLE.ACTIONS.MINOR.TRANSFORM
BATTLE.ACTIONS.MINOR.MEGA
BATTLE.ACTIONS.MINOR.ACTIVATE
BATTLE.ACTIONS.MINOR.HINT
BATTLE.ACTIONS.MINOR.CENTER
BATTLE.ACTIONS.MINOR.MESSAGE

GLOBAL.POPUP
GLOBAL.PM
GLOBAL.USERCOUNT
GLOBAL.NAMETAKEN
GLOBAL.CHALLSTR
GLOBAL.UPDATEUSER
GLOBAL.FORMATS
GLOBAL.UPDATESEARCH
GLOBAL.UPDATECHALLENGES
GLOBAL.QUERYRESPONSE
```

### `type UpdateUserMessage = DataMessage & {data: {username: UserId, named: boolean, avatar: Avatar}}`
A `DataMessage` where `message.type = MESSAGE_TYPES.GLOBAL.UPDATEUSER` and
`message.data` contains the updated user. This `Message` is used by multiple
events.

## Events
The return values of all event handlers with a return type of `void` are
ignored.

### `'connect': () => void`
Fires after the underlying WebSocket connects to the main server.

### `'disconnect': (code: unsigned short, message: ?) => void`
Fires after the underlying WebSocket disconnects from the main server. Passes
the arguments from the underlying WebSocket closing.

See
[WebSocket CloseEvent](https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent)
and the
[`ws` 'close' event](https://github.com/websockets/ws/blob/master/doc/ws.md#event-close).

### `'ready': () => void`
Fires after the client has connected and received a `challstr` (and is thus
ready to authenticate).

Calling `client.login(username, [password])` before this event fires results
in undefined behaviour.

### `'login': (message: UpdateUserMessage) => void`
Fires after a successful login. Passes the updated user. This fires _in
addition_ to the `self:changed` event.

See
[UpdateUserMessage](#type-updateusermessage--datamessage--data-username-string-named-boolean-avatar-integer).

### `'message': (message: Message) => void`
Fires after any message is received. Passes the parsed message.

### `'info:popup': (message: Message & TODO) => void`

### `'info:usercount': (message: Message & TODO) => void`

### `'info:formats': (message: Message & TODO) => void`

### `'info:search': (message: Message & TODO) => void`

### `'info:query': (message: Message & TODO) => void`


### `'self:changed': (message: UpdateUserMessage) => void`
Fires after the user is updated (e.g. after a successful login or avatar
change). Passes the updated user.

### `'self:challenges': (message: Message & TODO) => void`


### `'chat:private': (message: Message & TODO) => void`

### `'chat:message': (message: Message & TODO) => void`

### `'chat:html': (message: Message & TODO) => void`

### `'chat:uhtml': (message: Message & TODO) => void`

### `'chat:uhtmlchange': (message: Message & TODO) => void`

### `'chat:public': (message: Message & TODO) => void`

### `'chat:public': (message: Message & TODO) => void`

### `'chat:timestamp': (message: Message & TODO) => void`

### `'chat:raw': (message: Message & TODO) => void`


### `'room:joined': (message: Message & TODO) => void`

### `'room:left': (message: Message & TODO) => void`

### `'room:title': (message: Message & TODO) => void`

### `'room:users': (message: Message & TODO) => void`


### `'user:joined': (message: Message & TODO) => void`

### `'user:left': (message: Message & TODO) => void`

### `'user:changed': (message: Message & TODO) => void`


### `'battle:start': (message: DataMessage & {data: {roomid: RoomId, user1: UserId, user2: UserId}}) => void`
Fires after a battle begins. Passes the ID of the room and the users in the
battle.

### `'error:login': (message: DataMessage & {data: {username: UserId, message: string}}) => void`
Fires after encountering a login error. Generally due to a name being taken.
Passes the username in the login attempt and a message from the server.

### `'internal:send': (payload: string) => void`
Fires after sending a message to the main server. Passes the sent payload.

### `'internal:raw': (data: string) => void`
Fires after receiving a message from the main server. Passes the raw data
received.

### `'internal:unknown': (message: StringMessage) => void`
Fires after parsing an unknown message. Passes a `StringMessage` where
`message.type = MESSAGE_TYPES.OTHER.UNKNOWN` and `message.data` contains the raw
message contents.

## Methods

### `connect: () => Promise<void>`
Connects to the main server and returns a `Promise` which fulfils upon opening
the underlying WebSocket.

Fires the [`'connect'` event](#connect---void) on success.

### `disconnect: () => Promise<code: string, message: ?>`
Disconnects from the main server and returns a `Promise` which fulfils upon
closing the underlying WebSocket with the arguments of the
[`ws` 'close' event](https://github.com/websockets/ws/blob/master/doc/ws.md#event-close).

Fires the [`'disconnect'` event](#disconnect-code-unsigned-short-message---void)
on success.

### `send: (message: string, room: ?RoomId) => void`
Sends a message to a specific room. If no room is specified, the server
implicitly treats it as a global message.

Fires the [`'internal:send'` event](#internalsend-payload-string--void) after
sending.

### `login: (username: UserId, password: ?string) => Promise<UpdateUserMessage>`
Attempts to negotiate authentication using the provided username and password
and returns a `Promise` which fulfils upon success with the resulting
`UpdateUserMessage`.

The `password` argument is optional, although registered names require passwords
to authenticate.

Fires the [`'login'` event](#login-updateusermessage--void) on success.

Fires the [`'error:login'` event](#errorlogin-message-message--todo--void) on
failure. This is generally because the username is taken or password is
incorrect.
