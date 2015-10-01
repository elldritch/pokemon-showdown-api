EventEmitter = require 'events'

Promise = require 'bluebird'
WebSocket = require 'ws'
request = Promise.promisify require 'request'
sanitize = require 'sanitize-html'

{toMessageType, MESSAGE_TYPES} = require './symbols'
{ChatRoom} = require './ChatRoom'
{Battle} = require './Battle'

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
    roomId = 'Lobby'

    makingNewRoom = false
    newRoom = messages: []

    for message in messages
      @emit 'internal:message', message

      switch message.type
        when MESSAGE_TYPES.GLOBAL.POPUP
          null
        when MESSAGE_TYPES.GLOBAL.PM
          null
        when MESSAGE_TYPES.GLOBAL.USERCOUNT
          null
        when MESSAGE_TYPES.GLOBAL.NAMETAKEN
          null
        when MESSAGE_TYPES.GLOBAL.CHALLSTR
          @_challstr = message.data
          @emit 'ready'
        when MESSAGE_TYPES.GLOBAL.UPDATEUSER
          @emit 'internal:updateuser'
        when MESSAGE_TYPES.GLOBAL.FORMATS
          null
        when MESSAGE_TYPES.GLOBAL.UPDATESEARCH
          null
        when MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
          @emit 'challenge', message.data
        when MESSAGE_TYPES.GLOBAL.QUERYRESPONSE
          null

        when MESSAGE_TYPES.ROOM_INIT.INIT
          makingNewRoom = true
          newRoom.type = message.data
        when MESSAGE_TYPES.ROOM_INIT.TITLE
          newRoom.title = message.data
        when MESSAGE_TYPES.ROOM_INIT.USERLIST
          newRoom.users = message.data

        when MESSAGE_TYPES.ROOM_MESSAGES.ROOMID
          room = message.data

        when MESSAGE_TYPES.OTHER.UNKNOWN
          @emit 'internal:unknown'

        else
          if makingNewRoom
            newRoom.messages.push message
          else
            @rooms[roomId]._handle message

    if makingNewRoom
      switch newRoom.type
        when 'chat'
          room = new ChatRoom()
        when 'battle'
          room = new Battle()
      room.users = newRoom.users
      for message in newRoom.messages
        room._handle message

      @rooms[newRoom.title] = room
      @emit "init:#{newRoom.type}", room

  _lex: (data) -> (@_lexLine line for line in data.split '\n')

  _lexLine: (line) ->
    if line.startsWith '>'
      return {type: MESSAGE_TYPES.ROOM_MESSAGES.ROOMID, data: line.substr 1}
    if (line.startsWith '||') or not line.startsWith '|'
      return {type: MESSAGE_TYPES.ROOM_MESSAGES.MESSAGE, data: line}

    line = line.substr 1
    [type, data] = line.split /\|(.+)/
    type = type.toLowerCase()

    abbreviations =
      c: 'chat'
      'c:': 'chat'
      j: 'join'
      l: 'leave'
      n: 'name'
      b: 'battle'
      ':': 'timestamp'
      'users': 'userlist'

    if type of abbreviations then type = abbreviations[type]
    type = toMessageType type

    switch type
      when MESSAGE_TYPES.GLOBAL.POPUP
        return {type, data: data.replace /\|\|/g, '\n'}
      when MESSAGE_TYPES.GLOBAL.PM
        [sender, receiver, message] = data.split '|'
        return {type, data: {sender, receiver, message}}
      when MESSAGE_TYPES.GLOBAL.USERCOUNT
        return {type, data: parseInt data}
      when MESSAGE_TYPES.GLOBAL.NAMETAKEN
        [username, message] = data.split '|'
        return {type, data: {username, message}}
      when MESSAGE_TYPES.GLOBAL.CHALLSTR
        return {type, data}
      when MESSAGE_TYPES.GLOBAL.UPDATEUSER
        [username, named, avatar] = data.split '|'
        return {type, data: {username, named: named is '1', avatar}}
      when MESSAGE_TYPES.GLOBAL.FORMATS
        ###
        This server supports the formats specified in FORMATSLIST. FORMATSLIST
        is a |-separated list of FORMATs. FORMAT is a format name with one or
        more of these suffixes: ,# if the format uses random teams, ,, if the
        format is only available for searching, and , if the format is only
        available for challenging. Sections are separated by two vertical bars
        with the number of the column of that section prefixed by , in it. After
        that follows the name of the section and another vertical bar.

        TODO: finish implementation.
        ###
        formats = data.split '|'
        return {type, data: formats}
      when MESSAGE_TYPES.GLOBAL.UPDATESEARCH
        return {type, data: JSON.parse data}
      when MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
        return {type, data: JSON.parse data}
      when MESSAGE_TYPES.GLOBAL.QUERYRESPONSE
        [querytype, json] = data.split '|'
        return {type, data: {querytype, json: JSON.parse json}}

      when MESSAGE_TYPES.ROOM_INIT.INIT
        return {type, data}
      when MESSAGE_TYPES.ROOM_INIT.TITLE
        return {type, data}
      when MESSAGE_TYPES.ROOM_INIT.USERLIST
        return {type, data: data.split ', '}

      when MESSAGE_TYPES.ROOM_MESSAGES.HTML
        return {type, data: sanitize data}
      when MESSAGE_TYPES.ROOM_MESSAGES.JOIN
        return {type, data}
      when MESSAGE_TYPES.ROOM_MESSAGES.LEAVE
        return {type, data}
      when MESSAGE_TYPES.ROOM_MESSAGES.NAME
        [user, oldid] = data.split '|'
        return {type, data: {user, oldid}}
      when MESSAGE_TYPES.ROOM_MESSAGES.CHAT
        sections = data.split '|'
        if sections.length is 3
          timestamp = sections.shift()
        else
          timestamp = Date.now()
        [user, message] = sections
        return {type, data: {timestamp, user, message}}
      when MESSAGE_TYPES.ROOM_MESSAGES.TIMESTAMP
        return {type, data: new Date data}
      when MESSAGE_TYPES.ROOM_MESSAGES.BATTLE
        [roomid, user1, user2] = data.split '|'
        return {type, data: {roomid, user1, user2}}

    ###
    TODO: finish lexing rules

    BATTLE:
      PLAYER: Symbol.for 'psc:token:player'
      GAMETYPE: Symbol.for 'psc:token:gametype'
      GEN: Symbol.for 'psc:token:gen'
      TIER: Symbol.for 'psc:token:tier'
      RATED: Symbol.for 'psc:token:rated'
      RULE: Symbol.for 'psc:token:rule'
      CLEARPOKE: Symbol.for 'psc:token:clearpoke'
      POKE: Symbol.for 'psc:token:poke'
      TEAMPREVIEW: Symbol.for 'psc:token:teampreview'
      REQUEST: Symbol.for 'psc:token:request'
      INACTIVE: Symbol.for 'psc:token:inactive'
      INACTIVEOFF: Symbol.for 'psc:token:inactiveoff'
      START: Symbol.for 'psc:token:start'
      WIN: Symbol.for 'psc:token:win'
      TIE: Symbol.for 'psc:token:tie'

      ACTIONS:
        MAJOR:
          MOVE: Symbol.for 'psc:token:move'
          SWITCH: Symbol.for 'psc:token:switch'
          SWAP: Symbol.for 'psc:token:swap'
          DETAILSCHANGE: Symbol.for 'psc:token:detailschange'
          CANT: Symbol.for 'psc:token:cant'
          FAINT: Symbol.for 'psc:token:faint'
        MINOR:
          FAIL: Symbol.for 'psc:token:-fail'
          DAMAGE: Symbol.for 'psc:token:-damage'
          HEAL: Symbol.for 'psc:token:-heal'
          STATUS: Symbol.for 'psc:token:-status'
          CURESTATUS: Symbol.for 'psc:token:-curestatus'
          CURETEAM: Symbol.for 'psc:token:-cureteam'
          BOOST: Symbol.for 'psc:token:-boost'
          UNBOOST: Symbol.for 'psc:token:-unboost'
          WEATHER: Symbol.for 'psc:token:-weather'
          FIELDSTART: Symbol.for 'psc:token:-fieldstart'
          FIELDEND: Symbol.for 'psc:token:-fieldend'
          SIDESTART: Symbol.for 'psc:token:-sidestart'
          SIDEEND: Symbol.for 'psc:token:-sideend'
          CRIT: Symbol.for 'psc:token:-crit'
          SUPEREFFECTIVE: Symbol.for 'psc:token:-supereffective'
          RESISTED: Symbol.for 'psc:token:-resisted'
          IMMUNE: Symbol.for 'psc:token:-immune'
          ITEM: Symbol.for 'psc:token:-item'
          ENDITEM: Symbol.for 'psc:token:-enditem'
          ABILITY: Symbol.for 'psc:token:-ability'
          ENDABILITY: Symbol.for 'psc:token:-endability'
          TRANSFORM: Symbol.for 'psc:token:-transform'
          MEGA: Symbol.for 'psc:token:-mega'
          ACTIVATE: Symbol.for 'psc:token:-activate'
          HINT: Symbol.for 'psc:token:-hint'
          CENTER: Symbol.for 'psc:token:-center'
          MESSAGE: Symbol.for 'psc:token:-message'
      ACTIONREQUESTS:
        TEAM: Symbol.for 'psc:token:team'
        MOVE: Symbol.for 'psc:token:move'
        SWITCH: Symbol.for 'psc:token:switch'
        CHOOSE: Symbol.for 'psc:token:choose'
        UNDO: Symbol.for 'psc:token:undo'
    ###

    return {type: MESSAGE_TYPES.OTHER.UNKNOWN, data}

  @MESSAGE_TYPES: MESSAGE_TYPES

module.exports = {PokemonShowdownClient}
