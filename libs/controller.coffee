Korg = require 'korg-nano'
debug = require('debug')('hue-korg:controller')
events = require 'eventemitter2'

module.exports = class Controller extends events.EventEmitter2

  constructor: ->

    korg = new Korg
    korg.on '*', (e, value) =>
      debug "#{e} -> #{value}"

    korg.on 'knob:*', (e, value) =>
      name = e.split(/:/)[1]
      @emit 'knob', {name: name, value: value}

    korg.on 'slider:*', (e, value) =>
      name = e.split(/:/)[1]
      @emit 'slider', {name, name, value: value}

    korg.on 'button:*', (e, value) =>
      name = e.split(/:/)[1]
      @emit 'button', {name: name, value: value is 1}

    korg.on 'scene', (e, value) =>
      @emit 'scene', {value: value}
