EventEmitter = require 'events'

{MESSAGE_TYPES} = require './symbols'

class ChatRoom extends EventEmitter
  constructor: ->
    @users = []

  _handle: (message) ->
    switch message.type
      when MESSAGE_TYPES.ROOM_MESSAGES.CHAT
        @emit 'chat', message.data

module.exports = {ChatRoom}
