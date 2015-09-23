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

  prompt: -> @readlineInterface.prompt true
  print: (msg) ->
    @clear()
    @stdout.write msg.trim() + '\n'
    @prompt()

  # coffeelint: disable=no_backticks
  clear: -> @stdout.write `'\033[2K\033[2D'`
  # coffeelint: enable=no_backticks

ui = new Console()

client = new PokemonShowdownClient()
client.connect()

client
  .on 'connect', ->
    ui.print chalk.green 'connected (press CTRL+C to quit)'
    ui.on 'line', (line) ->
      if line.trim() is ':h'
        ui.print chalk.blue 'Usage:'
      else if line.match /:e (.*)/
        cmd = line.substr 3
          .trim()
        try
          ret = eval "client.#{cmd}"
          ui.print chalk.blue "returned: #{ret}"
        catch
          ui.print chalk.red 'that command is invalid'
      else
        client.socket.send line
      ui.prompt()
  .on 'disconnect', ->
    ui.print chalk.green 'disconnected'
    ui.clear()
    process.exit 0
  .on 'internal:message', (message) ->
    ui.print chalk.gray '< ' + message

ui.on 'close', -> process.exit 0
