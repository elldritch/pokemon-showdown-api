EventEmitter = require 'events'
readline = require 'readline'
util = require 'util'

chalk = require 'chalk'

{PokeClient} = require './'
{MESSAGE_TYPES} = PokeClient

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

dump = (obj) -> util.inspect obj, showHidden: true, depth: null

client = new PokeClient()
client.connect()

client
  .on 'connect', ->
    ui.print chalk.green 'connected (press CTRL+C to quit, :h for help)'
    ui.on 'line', (line) ->
      if line.trim() is ':h'
        ui.print chalk.blue '''
                            Usage:

                              :h       -- show this help page
                              :e [CMD] -- evaluate CMD

                            '''
      else if line.match /:e (.*)/
        cmd = line.substr 3
          .trim()
        try
          ret = eval cmd
          ui.print chalk.blue "returned: #{dump ret}"
        catch e
          ui.print chalk.red e
      else
        client.send line
      ui.prompt()
  .on 'disconnect', ->
    ui.print chalk.green 'disconnected'
    ui.clear()
    process.exit 0
  .on 'message', (message) ->
    switch message.type
      when MESSAGE_TYPES.OTHER.UNKNOWN
        ui.print chalk.inverse '< ' + dump message
      else
        ui.print '< ' + dump message
  .on 'error:*', (err) ->
    ui.print chalk.red '[ERROR] ' + JSON.stringify err
  .onAny (event, data) ->
    ui.print chalk.dim "#{event} #{dump data}"

ui.on 'close', -> process.exit 0
