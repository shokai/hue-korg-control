## switch debug npm / STDOUT&STDERR

class Logger

  constructor: (@debug) ->

  info: (msg) ->
    return @debug msg if @debug.enabled
    msg = JSON.stringify msg if typeof msg isnt 'string'
    console.log msg
  error: (msg) ->
    return @debug msg if @debug.enabled
    msg = JSON.stringify msg if typeof msg isnt 'string'
    console.error msg


module.exports = (debug) ->
  new Logger(debug)
