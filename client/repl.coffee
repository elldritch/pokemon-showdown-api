EventEmitter = require 'events'
readline = require 'readline'

chalk = require 'chalk'

{PokemonShowdownClient} = require './'

class Console extends EventEmitter
  constructor: ({
    @stdin = process.stdin,
    @stdout = process.stdout,
    @promptPrefix = '> '
  } = {}) ->
    @readlineInterface = readline.createInterface @stdin, @stdout
    @readlineInterface.setPrompt @promptPrefix
    @readlineInterface
      .on 'line', (data) => @emit 'line', data
      .on 'close', => @emit 'close'

  prompt: -> @readlineInterface.prompt true
  print: (msg) ->
    @clear()
    @stdout.write msg.trim() + '\n'
    @prompt()

  clear: ->
    readline.clearLine @stdout, 0
    readline.moveCursor @stdout, -1 * @promptPrefix.length, 0

ui = new Console()

client = new PokemonShowdownClient()
client.connect()

client
  .on 'connect', ->
    ui.print chalk.green 'connected (press CTRL+C to quit, :h for help)'
    ui.on 'line', (line) ->
      if line.trim() is ':h'
        ui.print chalk.blue '''
                            Usage:

                              :h       -- show this help page
                              :e [CMD] -- evaluate "client.CMD"

                            '''
      else if line.match /:e (.*)/
        cmd = line.substr 3
          .trim()
        try
          ret = eval "client.#{cmd}"
          ui.print chalk.blue "returned: #{ret}"
        catch e
          ui.print chalk.red e
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
