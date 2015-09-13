EventEmitter = require 'events'
readline = require 'readline'

chalk = require 'chalk'

{PokemonShowdownClient} = require './'

class Console extends EventEmitter
  constructor: ({@stdin = process.stdin, @stdout = process.stdout} = {}) ->
    @readlineInterface = readline.createInterface @stdin, @stdout
    @readlineInterface
      .on 'line', (data) => @emit 'line', data
      .on 'close', => @emit 'close'

  prompt: -> @readlineInterface.prompt()
  print: (msg) ->
    @clear()
    @stdout.write msg + '\n'
    @prompt()

  # coffeelint: disable=no_backticks
  clear: -> @stdout.write `'\033[2K\033[E'`
  # coffeelint: enable=no_backticks

ui = new Console()

client = new PokemonShowdownClient()
client.connect()

client
  .on 'connect', ->
    ui.print chalk.green 'connected (press CTRL+C to quit)'
    ui.on 'line', (line) ->
      if line.match /:e (.*)/
        cmd = line.substr 3
          .trim()
        eval cmd
      else
        client.send line
      ui.prompt()
  .on 'disconnect', ->
    ui.print chalk.green 'disconnected'
    ui.clear()
    process.exit 0
  .on 'internal:message', (message) ->
    ui.print chalk.blue '< ' + message

ui.on 'close', -> process.exit 0
