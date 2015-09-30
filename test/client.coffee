{expect} = require 'chai'
{PokemonShowdownClient} = require '../src'

describe 'PokemonShowdownClient', ->
  it 'should be tested'

  # This is a temporary sanity check test.
  # NOTE: This relies on the play.pokemonshowdown.com's implementation details,
  # and so will be flakey.
  # coffeelint: disable=missing_fat_arrows
  it 'can connect and challenge others', (done) ->
  # coffeelint: enable=missing_fat_arrows
    @timeout 5 * 1000
    alice = new PokemonShowdownClient()
    alice.connect()
    alice.on 'ready', -> alice.login 'alice-the-pscbot'
    alice.on 'login', -> alice.send '/join lobby'

    bob = new PokemonShowdownClient()
    bob.connect()
    bob.on 'ready', -> bob.login 'bob-the-pscbot'
    bob.on 'login', -> bob.send '/join lobby'

    alice.on 'challenge', (challenges) ->
      expect(challenges).to.have.property 'challengeTo', null
      expect(challenges).to.have.deep.property 'challengesFrom.bobthepscbot',
        'randombattle'
      done()

    bob.on 'internal:message', (message) ->
      if message.type is PokemonShowdownClient.MESSAGE_TYPES.ROOM_INIT.INIT
        bob.challenge 'alice-the-pscbot', format: 'randombattle'
