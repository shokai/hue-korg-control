"use strict";

var path  = require("path");
var async = require("async");

var debug = require("debug")("hue-korg");
var Logger = require(path.join(__dirname, "libs/logger"));
var logger = new Logger(debug);

var nanoKONTROL = require("korg-nano-kontrol");
var Hue = require("philips-hue");
var hue = new Hue();

nanoKONTROL.connect()
.then(korg => {
  logger.info(`connected "${korg.name}"`);

  hue.loadConfigFile(`${process.env.HOME}/.hue-korg.json`, err => {
    if(err) return console.error(err);
    hue.emit("ready");
  });

  hue.once("ready", function(){
    logger.info("hue ready");

    var lightCount = 3;
    hue.lights((err, lights) => {
      if(err) return logger.error(err);
      lightCount = Object.keys(lights).length;
    });

    korg.on("slider:*", function(value){
      var name = this.event.split(/:/)[1] - 0;
      debug(`slider:${name} => ${value}`);
      setHueState(hue.light(name+1), {
        bri: Math.floor(254*value/127), // brightness
        on: value > 0
      }, (err, res) => {
        if(err) return logger.error(err);
        logger.info(res);
      });
    });

    korg.on("knob:*", function(value){
      var name = this.event.split(/:/)[1] - 0;
      debug(`knob:${name} => ${value}`);
      setHueState(hue.light(name+1), {
        hue: Math.floor(65534*value/127), // color
        sat: 254,
        effect: value === 0 ? "colorloop" : "none"
      }, (err, res) => {
        if(err) return logger.error(err);
        logger.info(res);
      });
    });

    korg.on("button:**", function(value){
      if(value !== true) return;
      var match = this.event.match(/^button:(\w+):(\d+)$/);
      if(!match) return;
      var type = match[1];
      var name = match[2] - 0;
      switch(type){
      case "a":
      case "s":
        setHueState(hue.light(name+1), { sat: 0 }); // white
        break;
      case "b":
      case "m":
        setHueState(hue.light(name+1), { alert: "lselect" }); // blink
        break;
      }
    });
  })
})

var timerIds = {};
function setHueState(light, state, callback){
  clearTimeout(timerIds[light.number]);
  timerIds[light.number] = setTimeout(function(){
    logger.info(`lights[${light.number}].setState ${JSON.stringify(state)}`);
    light.setState(state, callback);
  }, 100);
}
