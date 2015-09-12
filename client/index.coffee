EventEmitter = require 'events'

Promise = require 'bluebird'
WebSocket = require 'ws'

request = Promise.promisify require 'request'

# Utility functions for logging
# coffeelint: disable=no_empty_functions,no_debugger
DEBUG = true
log = if DEBUG then console.log else ->
# coffeelint: enable=no_empty_functions,no_debugger

# Utility functions for dealing with strings
## Remove a certain number of characters off the beginning and end of a string
snip = (str, offStart, offEnd) -> str.substring offStart, str.length - offEnd

## All characters until the next occurrence of delimiter.
untilNext = (str, delimiter) -> str.substring 0, str.indexOf delimiter

## All characters after the next occurrence of delimiter.
afterNext = (str, delimiter) -> str.substring 1 + str.indexOf delimiter

## Split on the first occurrence of delimiter.
splitFirst = (str, delimiter) -> [
  untilNext str, delimiter
  afterNext str, delimiter
]

# Utility functions for handling login server interaction
_loginServer = request.defaults
  url: 'https://play.pokemonshowdown.com/action.php'
  method: 'POST'
loginServer = (options) ->
  log '[LOGIN SERVER]', options
  _loginServer form: options

# This is a client for Pokemon Showdown.
class PokemonShowdownClient extends EventEmitter
  connect: ->
    @socket = new WebSocket 'ws://sim.smogon.com:8000/showdown/websocket'
    @socket.on 'message', (data, flags) =>
      @emit 'message', data
      @_handle data
    new Promise (resolve, reject) =>
      @socket.on 'open', =>
        @emit 'connect'
        resolve()

  disconnect: ->
    new Promise (resolve, reject) =>
      @socket.on 'close', (code, message) =>
        @emit 'disconnect', code, message
        resolve()
      @socket.close()

  login: (name, pass) ->
    if name and pass and pass.length > 0
      log '[HAD AUTH]', name, pass
      assertion = loginServer {
        act: 'login'
        name
        pass
        challstr: @_challstr
      }
      .spread (_, body) ->
        user = JSON.parse body.substr 1
        log '[LOGIN RESPONSE]', user
        user.assertion
    else if name
      log '[HAD NAME]', name, pass
      assertion = loginServer
        act: 'getassertion'
        userid: name
        challstr: @_challstr
      .spread (_, body) -> body
    else return

    assertion.then (assertion) =>
      log '[ASSERTION]', assertion

      @send "/trn #{name},0,#{assertion}"
      new Promise (resolve, reject) =>
        @.once 'internal:updateuser', =>
          @emit 'login'
          resolve()

  _handle: (data) ->
    log '[RECEIVED]', data

    lines = data.split '\n'
      .filter (line) -> line.length > 0
    lexed = (@_lex line for line in lines)

    for message in lexed
      log '[LEXED]', message

      switch message.type
        when @MESSAGE_TYPES.GLOBAL.CHALLSTR
          @_challstr = message.data
          @emit 'ready'
        when @MESSAGE_TYPES.GLOBAL.UPDATEUSER
          @emit 'internal:updateuser'
        when @MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
          log '[CODE DEBUG]', message.data
          for challenger in Object.keys message.data.challengesFrom
            @send "/accept #{challenger}"

  _lex: (data) ->
    log '[LEXING]', data

    if (data.startsWith '||') or not data.startsWith '|'
      return {type: @MESSAGE_TYPES.ROOM_MESSAGES.MESSAGE, data}

    data = data.substr 1
    [type, data] = splitFirst data, '|'
    type = type.toLowerCase()

    abbreviations =
      c: 'chat'
      j: 'join'
      l: 'leave'
      n: 'name'
      b: 'battle'
      'c:': 'chat-timestamp'

    if type of abbreviations then type = abbreviations[type]
    type = Symbol.for type

    switch type
      when @MESSAGE_TYPES.GLOBAL.UPDATEUSER
        [username, named, avatar] = data.split '|'
        named = named is '1'
        return {type, data: {username, named, avatar}}
      when @MESSAGE_TYPES.GLOBAL.QUERYRESPONSE
        [querytype, json] = data.split '|'
        json = JSON.parse json
        return {type, data: {querytype, json}}
      when @MESSAGE_TYPES.GLOBAL.CHALLSTR
        return {type, data}
      when @MESSAGE_TYPES.GLOBAL.FORMATS
        # NOTE: this implementation is incomplete
        formats = data.split '|'
        return {type, data: formats}
      when @MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
        return {type, data: JSON.parse data}

      when @MESSAGE_TYPES.ROOM_MESSAGES.CHAT_TIMESTAMP
        [timestamp, user, message] = data.split '|'
        return {type, data: {timestamp, user, message}}
      when @MESSAGE_TYPES.ROOM_MESSAGES.JOIN
        return {type, data}
      when @MESSAGE_TYPES.ROOM_MESSAGES.LEAVE
        return {type, data}

    return {type: @MESSAGE_TYPES.OTHER.UNKNOWN, data}

  MESSAGE_TYPES:
    OTHER:
      UNKNOWN: Symbol.for 'unknown'

    ROOM_INIT:
      INIT: Symbol.for 'init'
      USERLIST: Symbol.for 'userlist'

    ROOM_MESSAGES:
      MESSAGE: Symbol.for 'message'
      HTML: Symbol.for 'html'
      JOIN: Symbol.for 'join'
      LEAVE: Symbol.for 'leave'
      NAME: Symbol.for 'name'
      CHAT: Symbol.for 'chat'
      CHAT_TIMESTAMP: Symbol.for 'chat-timestamp'
      TIMESTAMP: Symbol.for 'timestamp'
      BATTLE: Symbol.for 'battle'

    BATTLE:
      PLAYER: Symbol.for 'player'
      GAMETYPE: Symbol.for 'gametype'
      GEN: Symbol.for 'gen'
      TIER: Symbol.for 'tier'
      RATED: Symbol.for 'rated'
      RULE: Symbol.for 'rule'
      CLEARPOKE: Symbol.for 'clearpoke'
      POKE: Symbol.for 'poke'
      TEAMPREVIEW: Symbol.for 'teampreview'
      REQUEST: Symbol.for 'request'
      INACTIVE: Symbol.for 'inactive'
      INACTIVEOFF: Symbol.for 'inactiveoff'
      START: Symbol.for 'start'
      WIN: Symbol.for 'win'
      TIE: Symbol.for 'tie'

      ACTIONS:
        MAJOR:
          MOVE: Symbol.for 'move'
          SWITCH: Symbol.for 'switch'
          SWAP: Symbol.for 'swap'
          DETAILSCHANGE: Symbol.for 'detailschange'
          CANT: Symbol.for 'cant'
          FAINT: Symbol.for 'faint'
        MINOR:
          FAIL: Symbol.for 'fail'
          DAMAGE: Symbol.for 'damage'
          HEAL: Symbol.for 'heal'
          STATUS: Symbol.for 'status'
          CURESTATUS: Symbol.for 'curestatus'
          CURETEAM: Symbol.for 'cureteam'
          BOOST: Symbol.for 'boost'
          UNBOOST: Symbol.for 'unboost'
          WEATHER: Symbol.for 'weather'
          FIELDSTART: Symbol.for 'fieldstart'
          FIELDEND: Symbol.for 'fieldend'
          SIDESTART: Symbol.for 'sidestart'
          SIDEEND: Symbol.for 'sideend'
          CRIT: Symbol.for 'crit'
          SUPEREFFECTIVE: Symbol.for 'supereffective'
          RESISTED: Symbol.for 'resisted'
          IMMUNE: Symbol.for 'immune'
          ITEM: Symbol.for 'item'
          ENDITEM: Symbol.for 'enditem'
          ABILITY: Symbol.for 'ability'
          ENDABILITY: Symbol.for 'endability'
          TRANSFORM: Symbol.for 'transform'
          MEGA: Symbol.for 'mega'
          ACTIVATE: Symbol.for 'activate'
          HINT: Symbol.for 'hint'
          CENTER: Symbol.for 'center'
          MESSAGE: Symbol.for 'message'
      ACTIONREQUESTS:
        TEAM: Symbol.for 'team'
        MOVE: Symbol.for 'move'
        SWITCH: Symbol.for 'switch'
        CHOOSE: Symbol.for 'choose'
        UNDO: Symbol.for 'undo'

    GLOBAL:
      POPUP: Symbol.for 'popup'
      PM: Symbol.for 'pm'
      USERCOUNT: Symbol.for 'usercount'
      NAMETAKEN: Symbol.for 'nametaken'
      CHALLSTR: Symbol.for 'challstr'
      UPDATEUSER: Symbol.for 'updateuser'
      FORMATS: Symbol.for 'formats'
      UPDATESEARCH: Symbol.for 'updatesearch'
      UPDATECHALLENGES: Symbol.for 'updatechallenges'
      QUERYRESPONSE: Symbol.for 'queryresponse'

  send: (message, {room = ''} = {}) ->
    log '[SENDING]', room + '|' + message
    @socket.send room + '|' + message

module.exports = {PokemonShowdownClient}
