{PokemonShowdownClient} = require './client'
chalk = require 'chalk'

alice = new PokemonShowdownClient()
alice.connect()
alice.on 'ready', -> alice.login 'alice-the-combot'
alice.on 'login', -> alice.send '/join lobby'

bob = new PokemonShowdownClient()
bob.connect()
bob.on 'ready', -> bob.login 'bob-the-combot'
bob.on 'login', -> bob.send '/join lobby'

# coffeelint: disable=no_debugger
alice.on 'challenge', (challenges) ->
  console.log '[CHALLENGE]', challenges

bob.on 'internal:lexed', (message) ->
  if message.type is PokemonShowdownClient.MESSAGE_TYPES.ROOM_INIT.INIT
    console.log '[INIT]' + JSON.stringify message
    bob.send '/challenge alice-the-combot,randombattle'
  # else
  #   console.log chalk.grey '[MESSAGE]' + JSON.stringify message
