path = require 'path'

_ = require 'lodash'
debug = require('debug')('hue-korg')

Controller = require path.join __dirname, 'libs/controller'
controller = new Controller
Hue = require path.join __dirname, 'libs/hue'
hue = new Hue

setHueState = (light, state, callback) ->
  debug "setState #{JSON.stringify state}"
  light.setState state, callback

setHueStateThrottled = _.debounce setHueState, 300, trailing: true

hue.once 'ready', ->
  debug 'hue ready'

  controller.on 'slider', (data) ->
    setHueStateThrottled hue.light(data.name),
      bri: Math.floor 254*data.value
      sat: 254
      on: data.value > 0
    , (err, res) ->
      return console.error err if err
      debug res

  controller.on 'knob', (data) ->
    setHueStateThrottled hue.light(data.name),
      hue: Math.floor 65534*data.value
      sat: 254
    , (err, res) ->
      return console.error err if err
      debug res

  controller.on 'button', (data) ->
    console.log data
