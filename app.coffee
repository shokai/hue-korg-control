process.env.HUE_LIGHTS ||= 3

path = require 'path'

_     = require 'lodash'
async = require 'async'

debug  = require('debug')('hue-korg')
logger = require(path.join __dirname, 'libs/logger')(debug)

Controller = require path.join __dirname, 'libs/controller'
controller = new Controller
Hue = require 'philips-hue'
hue = new Hue

hue.loadConfigFile "#{process.env.HOME}/.hue-korg.json", (err) ->
  return console.error err if err
  hue.emit 'ready'

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
    if 10 > data.name and data.name > 0 and data.value is true
      setHueStateThrottled hue.light(data.name),
        sat: 0  # white
      , (err, res) ->
        return logger.error err if err
        logger.info res
      return
    if 19 > data.name and data.name > 9 and data.value is true
      setHueStateThrottled hue.light(data.name - 9),
        alert: "lselect"
      , (err, res) ->
        return logger.error err if err
        logger.info res
      return

  ## loopボタンでlselect開始、どのボタンを押してもlselect停止
  lselect_timer_id = null
  lselect_all = ->
    async.mapSeries [1..process.env.HUE_LIGHTS], (i, next) ->
      setHueStateThrottled hue.light(i),
        alert: "lselect"
      , next
    , (err, res) ->
      logger.error JSON.stringify err if err
      logger.info JSON.stringify res
  controller.on 'button', (data) ->
    return if data.value isnt true
    clearInterval lselect_timer_id
    if data.name is 'loop'
      lselect_all()
      lselect_timer_id = setInterval lselect_all, 15000
      return

setHueState = (light, state, callback) ->
  logger.info "lights[#{light.number}].setState #{JSON.stringify state}"
  light.setState state, callback

setHueStateThrottled = _.debounce setHueState, 300, trailing: true
