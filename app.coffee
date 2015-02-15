path = require 'path'

_ = require 'lodash'
debug = require('debug')('hue-korg')

logger = require(path.join __dirname, 'libs/logger')(debug)

Controller = require path.join __dirname, 'libs/controller'
controller = new Controller
Hue = require path.join __dirname, 'libs/hue'
hue = new Hue

setHueState = (light, state, callback) ->
  logger.info "setState #{JSON.stringify state}"
  light.setState state, callback

setHueStateThrottled = _.debounce setHueState, 300, trailing: true

hue.once 'ready', ->
  logger.info 'hue ready'

  controller.on 'slider', (data) ->
    setHueStateThrottled hue.light(data.name),
      bri: Math.floor 254*data.value
      sat: 254
      on: data.value > 0
    , (err, res) ->
      return logger.error err if err
      logger.info res

  controller.on 'knob', (data) ->
    setHueStateThrottled hue.light(data.name),
      hue: Math.floor 65534*data.value
      sat: 254
    , (err, res) ->
      return logger.error err if err
      logger.info res

  controller.on 'button', (data) ->
    logger.info data
