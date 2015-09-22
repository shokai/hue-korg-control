// switch debug npm / STDOUT&STDERR

"use strict";

export default class Logger{

  constructor(debug){
    this.debug = debug;
  }

  info(msg){
    if(this.debug.enabled){
      return this.debug(msg);
    }
    if(typeof msg !== "string"){
      msg = JSON.stringify(msg);
    }
    console.log(msg);
  }

  error(msg){
    if(this.debug.enabled){
      return this.debug(msg);
    }
    if(typeof msg !== "string"){
      msg = JSON.stringify(msg);
    }
    console.error(msg);
  }

}
