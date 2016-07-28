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
    @rooms =
      global:
        type: 'chat'
        messages: []
        users: []
      lobby:
        type: 'chat'
        messages: []
        users: []
    @user = {}

    @_challstr = ''
    @_loginRequest = request.defaults
      url: @_loginServer
      method: 'POST'
    @_login = (options) -> @_loginRequest form: options

  connect: ->
    @socket = new WebSocket @_server
    @socket.on 'message', (data, flags) => @_handle data
    new Promise (resolve, reject) =>
      @socket.on 'open', =>
        @emit 'connect'
        resolve()

  disconnect: ->
    done = new Promise (resolve, reject) =>
      @socket.on 'close', (code, message) =>
        @emit 'disconnect', code, message
        resolve code, message
    @socket.close()
    done

  login: (name, password) ->
    if name and password and password.length > 0
      assertion = @_login {
        act: 'login'
        name
        password
        challstr: @_challstr
      }
      .then ({body}) ->
        user = JSON.parse body.substr 1
        user.assertion
    else if name
      assertion = @_login {
        act: 'getassertion'
        userid: name
        challstr: @_challstr
      }
      .then ({body}) -> body
    else return

    assertion.then (assertion) =>
      @send "/trn #{name},0,#{assertion}"
      new Promise (resolve, reject) =>
        @.once 'login', -> resolve()

  send: (message, room = '') ->
    payload = "#{room}|#{message}"
    @emit 'internal:send', payload
    @socket.send payload

  _handle: (data) ->
    @emit 'internal:raw', data
    messages = @_lex data

    for message in messages
      @emit 'internal:message', message

      unless message.room of @rooms
        @rooms[message.room] = messages: [], users: [], type: 'unknown'
      @rooms[message.room].messages.push message

      switch message.type
        when MESSAGE_TYPES.GLOBAL.POPUP
          null
        when MESSAGE_TYPES.GLOBAL.PM
          null
        when MESSAGE_TYPES.GLOBAL.USERCOUNT
          null
        when MESSAGE_TYPES.GLOBAL.NAMETAKEN
          @emit 'error',
            action: 'login'
            code: 'ERR_LOGIN_NAME_TAKEN'
            message: 'Name already taken'
        when MESSAGE_TYPES.GLOBAL.CHALLSTR
          @_challstr = message.data
          @emit 'ready'
        when MESSAGE_TYPES.GLOBAL.UPDATEUSER
          @emit 'login'
          @user = message.data
        when MESSAGE_TYPES.GLOBAL.FORMATS
          null
        when MESSAGE_TYPES.GLOBAL.UPDATESEARCH
          null
        when MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
          @emit 'challenge', message.data
        when MESSAGE_TYPES.GLOBAL.QUERYRESPONSE
          null

        when MESSAGE_TYPES.ROOM_INIT.INIT
          @emit 'new-room', message.room
          @rooms[message.room].type = message.data
        when MESSAGE_TYPES.ROOM_INIT.TITLE
          @rooms[message.room].title = message.data
        when MESSAGE_TYPES.ROOM_INIT.USERS
          @rooms[message.room].users = message.data

        when MESSAGE_TYPES.ROOM_MESSAGES.JOIN
          @rooms[message.room].users.push message.data
        when MESSAGE_TYPES.ROOM_MESSAGES.LEAVE
          for i in [0...@rooms[message.room].users.length]
            if @rooms[message.room].users[i] is message.data
              @rooms[message.room].users.splice i, 1
              break
        when MESSAGE_TYPES.ROOM_MESSAGES.NAME
          for i in [0...@rooms[message.room].users.length]
            if @rooms[message.room].users[i] is message.data.oldid
              @rooms[message.room].users[i] = message.data.user
              break

        when MESSAGE_TYPES.OTHER.UNKNOWN
          @emit 'internal:unknown'

  _lex: (data) ->
    lines = data.split '\n'

    room = null
    if lines[0].startsWith '>'
      room = lines[0].substr 1
      lines = lines.slice 1
    else
      room = 'lobby'

    messages = (@_lexLine line for line in lines)
    for message in messages
      unless message.room
        message.room = room

    messages

  _lexLine: (line) ->
    if (line.startsWith '||') or not line.startsWith '|'
      return {type: MESSAGE_TYPES.ROOM_MESSAGES.MESSAGE, data: line}

    line = line.substr 1
    [type, data] = line.split /\|(.+)/

    abbreviations =
      c: 'chat'
      j: 'join'
      J: 'join'
      l: 'leave'
      L: 'leave'
      n: 'name'
      N: 'name'
      b: 'battle'
      B: 'battle'

    specialCases =
      'c:': 'chat+timestamp'
      ':': 'timestamp'

    if type of abbreviations then type = abbreviations[type]
    if type of specialCases then type = specialCases[type]
    type = toMessageType type

    switch type
      when MESSAGE_TYPES.GLOBAL.POPUP
        return {type, data: data.replace /\|\|/g, '\n', room: 'global'}
      when MESSAGE_TYPES.GLOBAL.PM
        [sender, receiver, message] = data.split '|'
        return {type, data: {sender, receiver, message}, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.USERCOUNT
        return {type, data: parseInt data, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.NAMETAKEN
        [username, message] = data.split '|'
        return {type, data: {username, message}, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.CHALLSTR
        return {type, data, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.UPDATEUSER
        [username, named, avatar] = data.split '|'
        return {type, data: {username, named: named is '1', avatar}, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.FORMATS
        # The documentation for this in PROTOCOL.md seems out-of-date. The
        # section titles are correct, but not the suffixes.
        formats = data.split '|'
        return {type, data: formats, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.UPDATESEARCH
        return {type, data: JSON.parse data, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
        return {type, data: JSON.parse data, room: 'global'}
      when MESSAGE_TYPES.GLOBAL.QUERYRESPONSE
        [querytype, json] = data.split '|'
        return {type, data: {querytype, json: JSON.parse json}, room: 'global'}

      when MESSAGE_TYPES.ROOM_INIT.INIT
        return {type, data}
      when MESSAGE_TYPES.ROOM_INIT.TITLE
        return {type, data}
      when MESSAGE_TYPES.ROOM_INIT.USERS
        return {type, data: data.split ', '}

      when MESSAGE_TYPES.ROOM_MESSAGES.HTML
        return {type, data: sanitize data}
      when MESSAGE_TYPES.ROOM_MESSAGES.RAW
        return {type, data: sanitize data}
      when MESSAGE_TYPES.ROOM_MESSAGES.JOIN
        return {type, data: data.trim()}
      when MESSAGE_TYPES.ROOM_MESSAGES.LEAVE
        return {type, data: data.trim()}
      when MESSAGE_TYPES.ROOM_MESSAGES.NAME
        [user, oldid] = data.split '|'
        return {type, data: {user, oldid}}
      when MESSAGE_TYPES.ROOM_MESSAGES.CHAT
        [user, message] = data.split '|'
        return {type, data: {user, message}}
      when MESSAGE_TYPES.ROOM_MESSAGES.CHAT_TIMESTAMP
        [timestamp, user, message] = data.split '|'
        timestamp = new Date 1000 * parseInt timestamp
        return {type, data: {timestamp, user, message}}
      when MESSAGE_TYPES.ROOM_MESSAGES.TIMESTAMP
        return {type, data: new Date 1000 * parseInt data}
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

  challenge: (name, {format = 'randombattle', room = ''}) -> @send "/challenge #{name},#{format}", room
  accept: (user) -> @send "/accept #{user}"
  reject: (user) -> @send "/reject #{user}"

  join: (room) -> @send "/join #{room}"

  away: -> @send '/away'
  back: -> @send '/back'

  avatar: (avatar) -> @send "/avatar #{avatar}"

  rating: (user) -> @send "/rating #{user}"

  ignore: (user) -> @send "/ignore #{user}"
  unignore: (user) -> @send "/unignore #{user}"
  ignorelist: -> @send '/ignorelist'

  data: (query) -> @send "/data #{query}"

###
COMMANDS: /nick, /avatar, /rating, /whois, /msg, /reply, /ignore, /away, /back, /timestamps, /highlight
INFORMATIONAL COMMANDS: /data, /dexsearch, /movesearch, /groups, /faq, /rules, /intro, /formatshelp, /othermetas, /learn, /analysis, /calc (replace / with ! to broadcast. Broadcasting requires: + % @ * # & ~)
For an overview of room commands, use /roomhelp
For details of a specific command, use something like: /help data
###

module.exports = {PokemonShowdownClient}
