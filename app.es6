"use strict";

import async from "async";
import _ from "lodash";

const debug = require("debug")("hue-korg");
import Logger from "./libs/logger";
const logger = new Logger(debug);

import * as nanoKONTROL from "korg-nano-kontrol";
import Hue from "philips-hue";
const hue = new Hue();

nanoKONTROL.connect()
.then(korg => {
  logger.info(`connected "${korg.name}"`);

  hue.loadConfigFile(`${process.env.HOME}/.hue-korg.json`, (err) => {
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

    // playボタンでlselect, loopボタンでcolorloop開始
    // どのボタンを押してもlselect/colorloop停止
    var lselect_timer_id = null;
    function lselect_all(){
      async.mapSeries(_.range(1, lightCount+1), (i, next) => {
        setHueState(hue.light(i), {
          alert: "lselect"
        }, next);
      }, (err, res) => {
        if(err) return logger.error(JSON.stringify(err));
        logger.info(JSON.stringify(res));
      });
    }

    function colorloop_all(enable = true){
      async.mapSeries(_.range(1, lightCount+1), (i, next) => {
        setHueState(hue.light(i), {
          effect: enable ? "colorloop" : "none"
        }, next);
      }, (err, res) => {
        if(err) return logger.error(JSON.stringify(err));
        logger.info(JSON.stringify(res));
      });
    }

    korg.on("button:*", function(value){
      var name = this.event.match(/button:(.+)/)[1];
      debug(`button:${name} => ${value}`);
      if(value !== true) return;
      clearInterval(lselect_timer_id);
      switch(name){
      case "play":
        lselect_all();
        lselect_timer_id = setInterval(lselect_all, 15000);
        break;
      case "loop":
      case "cycle":
        colorloop_all(true);
        break;
      case "stop":
        colorloop_all(false);
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
