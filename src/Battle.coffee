EventEmitter = require 'events'

{MESSAGE_TYPES} = require './symbols'

class Battle extends EventEmitter
  constructor: ->
    @players = {}
    @rated = false
    @gametype = ''
    @gen = 0
    @tier = ''
    @rules = []

  _handle: (message) ->
    switch message.type
      when MESSAGE_TYPES.BATTLE.REQUEST
        @emit 'turn', message.data
      when MESSAGE_TYPES.ROOM_MESSAGES.INACTIVE
        @emit 'timer', true
      when MESSAGE_TYPES.ROOM_MESSAGES.INACTIVEOFF
        @emit 'timer', false


module.exports = {Battle}
