path = require 'path'
_    = require 'lodash'

debug  = require('debug')('hue-korg')
logger = require(path.join __dirname, 'libs/logger')(debug)

Controller = require path.join __dirname, 'libs/controller'
controller = new Controller
Hue = require path.join __dirname, 'libs/hue'
hue = new Hue

hue.once 'ready', ->
  logger.info 'hue ready'

  controller.on 'slider', (data) ->
    setHueStateThrottled hue.light(data.name),
      bri: Math.floor 254*data.value  # brightness
      on: data.value > 0
    , (err, res) ->
      return logger.error err if err
      logger.info res

  controller.on 'knob', (data) ->
    setHueStateThrottled hue.light(data.name),
      hue: Math.floor 65534*data.value  # color
      sat: 254
      effect: if data.value is 1 then "colorloop" else "none"
    , (err, res) ->
      return logger.error err if err
      logger.info res

  controller.on 'button', (data) ->
    if data.name > 0 and data.value is true
      setHueStateThrottled hue.light(data.name),
        sat: 0  # white
      , (err, res) ->
        return logger.error err if err
        logger.info res

setHueState = (light, state, callback) ->
  logger.info "lights[#{light.number}].setState #{JSON.stringify state}"
  light.setState state, callback

setHueStateThrottled = _.debounce setHueState, 300, trailing: true
