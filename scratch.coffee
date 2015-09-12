{PokemonShowdownClient} = require './client'

client = new PokemonShowdownClient()

client.connect()

client.on 'ready', ->
  console.log '[READY]'
  # client.login 'anunktanenaerm'
  client.login 'bitwise', 'Qq3$U!tdBHJ&'

client.on 'login', ->
  console.log '[LOGGED IN]'
  client.send '/help'
  client.send '/join lobby'
  # client.send '/roomhelp'

# setTimeout (-> client.disconnect()), 10000
