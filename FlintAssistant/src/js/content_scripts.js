(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
forge.logging.info('FlintAssistant content-script is running ...');

window.addEventListener('message', (function(_this) {
  return function(event) {
    var callback, error, message;
    message = event.data;
    if ((message != null ? message.to : void 0) !== 'content-script') {
      return;
    }
    if (typeof message.payload === void 0) {
      return;
    }
    callback = function(payload) {
      return window.postMessage({
        to: 'page-script',
        payload: payload
      }, '*');
    };
    error = function(error) {
      return console.error(error);
    };
    return forge.message.broadcastBackground('message', message.payload, callback, error);
  };
})(this));



},{}]},{},[1]);
