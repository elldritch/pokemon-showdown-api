EventEmitter = require 'events'

Promise = require 'bluebird'
WebSocket = require 'ws'
request = Promise.promisify require 'request'

{toMessageType, MESSAGE_TYPES} = require './symbols'
{ChatRoom} = require './ChatRoom'
{Battle} = require './Battle'

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

# This is a client for Pokemon Showdown.
class PokemonShowdownClient extends EventEmitter
  constructor: (
    @_server = 'ws://sim.smogon.com:8000/showdown/websocket',
    @_loginServer = 'https://play.pokemonshowdown.com/action.php'
  ) ->
    @socket = null
    @rooms = {}

    @_challstr = ''
    @_loginRequest = request.defaults
      url: @_loginServer
      method: 'POST'
    @_login = (options) -> @_loginRequest form: options

  connect: ->
    @socket = new WebSocket @_server
    @socket.on 'open', => @emit 'connect'
    @socket.on 'message', (data, flags) => @_handle data

  disconnect: ->
    @socket.on 'close', (code, message) => @emit 'disconnect', code, message
    @socket.close()

  login: (name, password) ->
    if name and password and password.length > 0
      assertion = @_login {
        act: 'login'
        name
        password
        challstr: @_challstr
      }
      .spread (_, body) ->
        user = JSON.parse body.substr 1
        user.assertion
    else if name
      assertion = @_login {
        act: 'getassertion'
        userid: name
        challstr: @_challstr
      }
      .spread (_, body) -> body
    else return

    assertion.then (assertion) =>
      @send "/trn #{name},0,#{assertion}"
      @.once 'internal:updateuser', => @emit 'login'

  challenge: (name, {format = 'randombattle', room = ''}) ->
    @send "/challenge #{name},#{format}", room

  respond: ({accept = [], reject = []}) ->
    for user in accept
      @send "/accept #{user}"

    for user in reject
      @send "/reject #{user}"

  send: (message, room = '') ->
    payload = "#{room}|#{message}"
    @emit 'internal:send', payload
    @socket.send payload

  _handle: (data) ->
    @emit 'internal:raw', data
    messages = @_lex data

    for message in messages
      @emit 'internal:message', message

      switch message.type
        when MESSAGE_TYPES.GLOBAL.CHALLSTR
          @_challstr = message.data
          @emit 'ready'
        when MESSAGE_TYPES.GLOBAL.UPDATEUSER
          @emit 'internal:updateuser'
        when MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
          @emit 'challenge', message.data
        when MESSAGE_TYPES.ROOM_INIT.INIT
          @emit 'internal:debug', message
          if message.data is 'chat'
            @rooms[message.room] = new ChatRoom()
          else if message.data is 'battle'
            @rooms[message.room] = new Battle()

      if message.room isnt 'global'
        @rooms[message.room]._handle message

  _lex: (data) ->
    lines = data.split '\n'

    if lines[0].startsWith '>'
      room = lines[0].substr 1
      lines.shift()
    else
      room = 'global'

    (@_lexLine line, room for line in lines)

  _lexLine: (line, room) ->
    if (line.startsWith '||') or not line.startsWith '|'
      return {type: MESSAGE_TYPES.ROOM_MESSAGES.MESSAGE, data: line, room}

    line = line.substr 1
    [type, data] = splitFirst line, '|'
    type = type.toLowerCase()

    abbreviations =
      c: 'chat'
      'c:': 'chat'
      j: 'join'
      l: 'leave'
      n: 'name'
      b: 'battle'

    if type of abbreviations then type = abbreviations[type]
    type = toMessageType type

    switch type
      when MESSAGE_TYPES.GLOBAL.UPDATEUSER
        [username, named, avatar] = data.split '|'
        named = named is '1'
        return {type, data: {username, named, avatar}, room}
      when MESSAGE_TYPES.GLOBAL.QUERYRESPONSE
        [querytype, json] = data.split '|'
        json = JSON.parse json
        return {type, data: {querytype, json}, room}
      when MESSAGE_TYPES.GLOBAL.CHALLSTR
        return {type, data, room}
      when MESSAGE_TYPES.GLOBAL.FORMATS
        # TODO: this implementation is incomplete
        formats = data.split '|'
        return {type, data: formats, room}
      when MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
        return {type, data: JSON.parse data, room}

      when MESSAGE_TYPES.ROOM_INIT.INIT
        return {type, data, room}

      when MESSAGE_TYPES.ROOM_MESSAGES.CHAT
        sections = data.split '|'
        if sections.length is 3
          timestamp = sections.shift()
        else
          timestamp = Date.now()
        [user, message] = sections
        return {type, data: {timestamp, user, message}, room}
      when MESSAGE_TYPES.ROOM_MESSAGES.JOIN
        return {type, data, room}
      when MESSAGE_TYPES.ROOM_MESSAGES.LEAVE
        return {type, data, room}

    return {type: MESSAGE_TYPES.OTHER.UNKNOWN, data, room}

  @MESSAGE_TYPES: MESSAGE_TYPES

module.exports = {PokemonShowdownClient}
