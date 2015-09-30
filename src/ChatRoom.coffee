EventEmitter = require 'events'

class ChatRoom extends EventEmitter
  constructor: ->
    @users = []
    @messages = []

  @_handle: (message) ->

module.exports = {ChatRoom}
