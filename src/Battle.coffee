EventEmitter = require 'events'

class Battle extends EventEmitter
  constructor: ->
    @players = {}
    @rated = false
    @gametype = ''
    @gen = 0
    @tier = ''
    @rules = []

  _handle: (message) ->

module.exports = {Battle}
