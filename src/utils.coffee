exports.logger = logger =
  _pad: (n) ->
    n = n + ''
    if n.length >= 2 then n else new Array(2 - n.length + 1).join('0') + n

  timestamp: ->
    d     = new Date()
    year  = d.getUTCFullYear()
    month = @_pad d.getUTCMonth() + 1
    date  = @_pad d.getUTCDate()
    hour  = @_pad d.getUTCHours()
    min   = @_pad d.getUTCMinutes()
    sec   = @_pad d.getUTCSeconds()
    "#{year}-#{month}-#{date} #{hour}:#{min}:#{sec}"

  log: (level, message, metadata = '') ->
    unless level == 'error'
      return console.log "#{@timestamp()} [#{level}] #{message}", metadata

    if message instanceof Error
      [err, message] = [message, message.name]

    console.error "#{@timestamp()} [#{level}] #{message}", metadata

    require('postmortem').prettyPrint err if err?

for level in ['info', 'debug', 'warn', 'error']
  do (level) ->
    logger[level] = (message, metadata) ->
      logger.log level, message, metadata

# serialize errors
exports.serialize = (err) ->
  message:              err.message
  name:                 err.name
  stack:                err.stack
  structuredStackTrace: err.structuredStackTrace

# deserialize error object back into error object
exports.deserialize = (err) ->
  # pull out bits we'll need
  {name, message, stack, structuredStackTrace} = err

  # recreate structuredStacktrace methods
  for frame in structuredStackTrace
    {path, line, isNative, name, type, method} = frame
    do (frame, path, line, isNative, name, type, method) ->
      frame.getFileName     = -> path
      frame.getLineNumber   = -> line
      frame.isNative        = -> isNative
      frame.getFunctionName = -> name
      frame.getTypeName     = -> type
      frame.getMethodName   = -> method

  # create new real error object
  err = new Error()
  err.name                 = name
  err.message              = message
  err.stack                = stack
  err.structuredStackTrace = structuredStackTrace
  err
