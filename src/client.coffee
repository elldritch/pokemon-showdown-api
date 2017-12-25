{EventEmitter2} = require 'eventemitter2'
Promise = require 'bluebird'
WebSocket = require 'ws'
request = Promise.promisify require 'request'
sanitize = require 'sanitize-html'

{toMessageType, MESSAGE_TYPES} = require './symbols'

# This is a client for Pokemon Showdown.
class PokeClient extends EventEmitter2
  constructor: (
    @_server = 'ws://sim.smogon.com:8000/showdown/websocket',
    @_loginServer = 'https://play.pokemonshowdown.com/action.php'
  ) ->
    @socket = null
    @user = null

    @_challstr = ''
    @_loginRequest = request.defaults
      url: @_loginServer
      method: 'POST'
    @_login = (options) -> @_loginRequest form: options

    super wildcard: true, delimiter: ':'

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

  login: (name, pass) ->
    if name and pass and pass.length > 0
      assertion = @_login {
        act: 'login'
        name
        pass
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
        @.once 'self:changed', (data) =>
          @emit 'login', data
          resolve()

  send: (message, room = '') ->
    payload = "#{room}|#{message}"
    @socket.send payload
    @emit 'internal:send', payload

  _handle: (data) ->
    @emit 'internal:raw', data
    messages = @_lex data

    for message in messages
      switch message.type
        when MESSAGE_TYPES.GLOBAL.POPUP
          @emit 'info:popup', message
        when MESSAGE_TYPES.GLOBAL.PM
          @emit 'chat:private', message
        when MESSAGE_TYPES.GLOBAL.USERCOUNT
          @emit 'info:usercount', message
        when MESSAGE_TYPES.GLOBAL.NAMETAKEN
          @emit 'error:login', message
        when MESSAGE_TYPES.GLOBAL.CHALLSTR
          @_challstr = message.data
          @emit 'ready'
        when MESSAGE_TYPES.GLOBAL.UPDATEUSER
          @user = message.data
          @emit 'self:changed', message
        when MESSAGE_TYPES.GLOBAL.FORMATS
          @emit 'info:formats', message
        when MESSAGE_TYPES.GLOBAL.UPDATESEARCH
          @emit 'info:search', message
        when MESSAGE_TYPES.GLOBAL.UPDATECHALLENGES
          @emit 'self:challenges', message
        when MESSAGE_TYPES.GLOBAL.QUERYRESPONSE
          @emit 'info:query', message

        when MESSAGE_TYPES.ROOM_INIT.INIT
          @emit 'room:joined', message
        when MESSAGE_TYPES.ROOM_INIT.DEINIT
          @emit 'room:left', message
        when MESSAGE_TYPES.ROOM_INIT.TITLE
          @emit 'room:title', message
        when MESSAGE_TYPES.ROOM_INIT.USERS
          @emit 'room:users', message

        when MESSAGE_TYPES.ROOM_MESSAGES.MESSAGE
          @emit 'chat:message', message
        when MESSAGE_TYPES.ROOM_MESSAGES.HTML
          @emit 'chat:html', message
        when MESSAGE_TYPES.ROOM_MESSAGES.UHTML
          @emit 'chat:uhtml', message
        when MESSAGE_TYPES.ROOM_MESSAGES.UHTMLCHANGE
          @emit 'chat:uhtmlchange', message
        when MESSAGE_TYPES.ROOM_MESSAGES.JOIN
          @emit 'user:joined', message
        when MESSAGE_TYPES.ROOM_MESSAGES.LEAVE
          @emit 'user:left', message
        when MESSAGE_TYPES.ROOM_MESSAGES.NAME
          @emit 'user:changed', message
        when MESSAGE_TYPES.ROOM_MESSAGES.CHAT
          message.data.timestamp = Date.now()
          @emit 'chat:public', message
        when MESSAGE_TYPES.ROOM_MESSAGES.CHAT_TIMESTAMP
          @emit 'chat:public', message
        when MESSAGE_TYPES.ROOM_MESSAGES.TIMESTAMP
          @emit 'chat:timestamp', message
        when MESSAGE_TYPES.ROOM_MESSAGES.BATTLE
          @emit 'battle:start', message
        when MESSAGE_TYPES.ROOM_MESSAGES.RAW
          @emit 'chat:raw', message

        when MESSAGE_TYPES.OTHER.UNKNOWN
          @emit 'internal:unknown', message

      @emit 'message', message

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
        named = named is '1'
        return {type, data: {username, named, avatar}, room: 'global'}
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
      when MESSAGE_TYPES.ROOM_INIT.DEINIT
        return {type, data}
      when MESSAGE_TYPES.ROOM_INIT.TITLE
        return {type, data}
      when MESSAGE_TYPES.ROOM_INIT.USERS
        return {type, data: data.split ', '}

      when MESSAGE_TYPES.ROOM_MESSAGES.HTML
        return {type, data: sanitize data}
      when MESSAGE_TYPES.ROOM_MESSAGES.UHTML
        [name, html] = data.split '|'
        return {type, data: {name, html: sanitize html}}
      when MESSAGE_TYPES.ROOM_MESSAGES.UHTMLCHANGE
        [name, html] = data.split '|'
        return {type, data: {name, html: sanitize html}}
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

      when MESSAGE_TYPES.BATTLE.PLAYER
        [player, username, avatar] = data.split '|'
        return {type, data: {player, username, avatar}}
      when MESSAGE_TYPES.BATTLE.GAMETYPE
        return {type, data}
      when MESSAGE_TYPES.BATTLE.GEN
        return {type, data: parseInt data}
      when MESSAGE_TYPES.BATTLE.TIER
        return {type, data}
      when MESSAGE_TYPES.BATTLE.RATED
        return {type}
      when MESSAGE_TYPES.BATTLE.RULE
        [name, description] = data.split ': '
        return {type, data: {name, description}}
      when MESSAGE_TYPES.BATTLE.CLEARPOKE
        null
      when MESSAGE_TYPES.BATTLE.POKE
        null
      when MESSAGE_TYPES.BATTLE.TEAMPREVIEW
        null
      when MESSAGE_TYPES.BATTLE.REQUEST
        return {type, data: JSON.parse data}
      when MESSAGE_TYPES.BATTLE.INACTIVE
        return {type, data}
      when MESSAGE_TYPES.BATTLE.INACTIVEOFF
        return {type, data}
      when MESSAGE_TYPES.BATTLE.START
        return {type}
      when MESSAGE_TYPES.BATTLE.WIN
        return {type, data}
      when MESSAGE_TYPES.BATTLE.TIE
        return {type}
      when MESSAGE_TYPES.BATTLE.ERROR
        [error, description] = data.split '] '
        error = error.replace /\[/, ''
        return {type, data: {error, description}}

      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.TURN
        return {type, data: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.MOVE
        [pokemon, move, target] = data.split '|'
        return {type, data: {pokemon, move, target}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.SWITCH
        [pokemon, details, hpStatus] = data.split '|'
        [hp, status] = hpStatus.split ' '
        return {type, data: {pokemon, details, hp, status}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.DRAG
        [pokemon, details, hpStatus] = data.split '|'
        [hp, status] = hpStatus.split ' '
        return {type, data: {pokemon, details, hp, status}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.SWAP
        [pokemon, position] = data.split '|'
        return {type, data: {pokemon, position}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.DETAILSCHANGE
        null
      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.CANT
        [pokemon, reason, move] = data.split '|'
        return {type, data: {pokemon, reason, move}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MAJOR.FAINT
        return {type, data: pokemon: data}

      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.FAIL
        [pokemon, action] = data.split '|'
        return {type, data: {pokemon, action}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.DAMAGE
        [pokemon, hpStatus] = data.split '|'
        [hp, status] = hpStatus.split ' '
        return {type, data: {pokemon, hp, status}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.HEAL
        [pokemon, hpStatus] = data.split '|'
        [hp, status] = hpStatus.split ' '
        return {type, data: {pokemon, hp, status}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.STATUS
        [pokemon, status] = data.split '|'
        return {type, data: {pokemon, status}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.CURESTATUS
        [pokemon, status] = data.split '|'
        return {type, data: {pokemon, status}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.CURETEAM
        return {type, data: pokemon: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.BOOST
        [pokemon, status, amount] = data.split '|'
        return {type, data: {pokemon, status, amount}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.UNBOOST
        [pokemon, status, amount] = data.split '|'
        return {type, data: {pokemon, status, amount}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.WEATHER
        return {type, data: weather: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.FIELDSTART
        return {type, data: condition: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.FIELDEND
        return {type, data: condition: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.SIDESTART
        [side, condition] = data.split '|'
        return {type, data: {side, condition}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.SIDEEND
        [side, condition] = data.split '|'
        return {type, data: {side, condition}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.CRIT
        return {type, data: pokemon: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.SUPEREFFECTIVE
        return {type, data: pokemon: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.RESISTED
        return {type, data: pokemon: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.IMMUNE
        return {type, data: pokemon: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.ITEM
        [pokemon, item] = data.split '|'
        return {type, data: {pokemon, item}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.ENDITEM
        [pokemon, item] = data.split '|'
        return {type, data: {pokemon, item}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.ABILITY
        [pokemon, ability] = data.split '|'
        return {type, data: {pokemon, ability}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.ENDABILITY
        return {type, data: pokemon: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.TRANSFORM
        [pokemon, species] = data.split '|'
        return {type, data: {pokemon, species}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.MEGA
        [pokemon, megastone] = data.split '|'
        return {type, data: {pokemon, megastone}}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.ACTIVATE
        return {type, data: effect: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.HINT
        return {type, data: message: data}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.CENTER
        return {type}
      when MESSAGE_TYPES.BATTLE.ACTIONS.MINOR.MESSAGE
        return {type, data: message: data}

      when MESSAGE_TYPES.OTHER.TOURNAMENT
        [updateType, update] = data.split '|'
        if updateType is 'update'
          update = JSON.parse update
        return {type, data: {updateType, update}}

    return {type: MESSAGE_TYPES.OTHER.UNKNOWN, data}

  @MESSAGE_TYPES: MESSAGE_TYPES

module.exports = {PokeClient}
