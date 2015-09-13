{PokemonShowdownClient} = require './client'

client = new PokemonShowdownClient()

client.connect()

# coffeelint: disable=no_debugger
client.on 'ready', ->
  console.log '[READY]'
  # client.login 'anunktanenaerm'
  client.login 'bitwise', 'Qq3$U!tdBHJ&'

client.on 'login', ->
  console.log '[LOGGED IN]'
  client.send '/help'
  client.send '/join lobby'
  # client.send '/roomhelp'
