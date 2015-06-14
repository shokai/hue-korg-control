path = require 'path'

async = require 'async'

debug  = require('debug')('hue-korg')
logger = require(path.join __dirname, 'libs/logger')(debug)

nanoKONTROL = require 'korg-nano-kontrol'
Hue = require 'philips-hue'
hue = new Hue

nanoKONTROL.connect()
.then (korg) ->
  logger.info "connected \"#{korg.name}\""

  hue.loadConfigFile "#{process.env.HOME}/.hue-korg.json", (err) ->
    return console.error err if err
    hue.emit 'ready'

  hue.once 'ready', ->
    logger.info 'hue ready'

    lightCount = 3
    hue.lights (err, lights) ->
      return logger.error err if err
      lightCount = Object.keys(lights).length

    korg.on 'slider:*', (value) ->
      name = @event.split(/:/)[1]-0
      debug "slider:#{name} => #{value}"
      setHueState hue.light(name+1),
        bri: Math.floor 254*value/127  # brightness
        on:  value > 0
      , (err, res) ->
        return logger.error err if err
        logger.info res

    korg.on 'knob:*', (value) ->
      name = @event.split(/:/)[1]-0
      debug "knob:#{name} => #{value}"
      setHueState hue.light(name+1),
        hue: Math.floor 65534*value/127  # color
        sat: 254
        effect: if value is 0 then "colorloop" else "none"
      , (err, res) ->
        return logger.error err if err
        logger.info res

    korg.on 'button:**', (value) ->
      return if value isnt true
      match = @event.match(/^button:(\w+):(\d)+$/)
      return unless match
      type = match[1]
      name = match[2]-0
      switch type
        when 'a', 's'
          setHueState hue.light(name+1),
            sat: 0  # white
        when 'b', 'm'
          setHueState hue.light(name+1),
            alert: 'lselect'  # blink

    ## playボタンでlselect、loopボタンでcolorloop開始
    ## どのボタンを押してもlselect/colorloop停止
    lselect_timer_id = null
    lselect_all = ->
      async.mapSeries [1..lightCount], (i, next) ->
        setHueState hue.light(i),
          alert: "lselect"
        , next
      , (err, res) ->
        logger.error JSON.stringify err if err
        logger.info JSON.stringify res

    colorloop_all = (enable = true) ->
      async.mapSeries [1..lightCount], (i, next) ->
        setHueState hue.light(i),
          effect: if enable then "colorloop" else "none"
        , next
      , (err, res) ->
        logger.error JSON.stringify err if err
        logger.info JSON.stringify res

    korg.on 'button:*', (value) ->
      name = @event.match(/button:(.+)/)[1]
      debug "button:#{name} => #{value}"
      return if value isnt true
      clearInterval lselect_timer_id
      switch name
        when 'play'
          lselect_all()
          lselect_timer_id = setInterval lselect_all, 15000
          return
        when 'loop', 'cycle'
          colorloop_all true
        when 'stop'
          colorloop_all false

timerIds = {}
setHueState = (light, state, callback) ->
  clearTimeout timerIds[light.number]
  timerIds[light.number] = setTimeout ->
    logger.info "lights[#{light.number}].setState #{JSON.stringify state}"
    light.setState state, callback
  , 100
