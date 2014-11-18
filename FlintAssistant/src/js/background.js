(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var callback, error, http_get, http_post, websocket_create, websocket_poll_event, websocket_send, websockets, xhr_create, xhr_open, xhr_poll_event, xhr_send, xhr_set_request_header, xhrs;

forge.logging.info("Flint extension background script is running !");

http_get = function(message, reply) {
  var key, xhr, _i, _len, _ref;
  xhr = new XMLHttpRequest();
  xhr.open("GET", message.params.url, true);
  if (message.params.headers) {
    _ref = message.params.headers;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      xhr.setRequestHeader(key, message.params.headers[key]);
    }
  }
  xhr.onreadystatechange = (function(_this) {
    return function() {
      var _ref1;
      if (xhr.readyState === 4) {
        if ((200 <= (_ref1 = xhr.status) && _ref1 < 300)) {
          return reply({
            callid: message.callid,
            status: 'success',
            content: {
              status: xhr.status,
              data: xhr.responseText
            }
          });
        } else {
          return reply({
            callid: message.callid,
            status: 'error',
            content: {
              status: xhr.status
            }
          });
        }
      }
    };
  })(this);
  return xhr.send(null);
};

http_post = function(message, reply) {
  var key, xhr, _i, _len, _ref;
  xhr = new XMLHttpRequest();
  xhr.open("POST", message.params.url, true);
  forge.logging.info("POST_URL : " + message.params.url);
  if (message.params.headers) {
    _ref = message.params.headers;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      forge.logging.info(key + " : " + message.params.headers[key]);
      xhr.setRequestHeader(key, message.params.headers[key]);
    }
  }
  xhr.onreadystatechange = (function(_this) {
    return function() {
      var _ref1;
      if (xhr.readyState === 4) {
        if ((200 <= (_ref1 = xhr.status) && _ref1 < 300)) {
          return reply({
            callid: message.callid,
            status: 'success',
            content: {
              status: xhr.status,
              data: xhr.responseText
            }
          });
        } else {
          return reply({
            callid: message.callid,
            status: 'error',
            content: {
              status: xhr.status
            }
          });
        }
      }
    };
  })(this);
  if (typeof message.params.data === 'string') {
    return xhr.send(message.params.data);
  } else {
    return xhr.send(JSON.stringify(message.params.data));
  }
};

websockets = {};

websocket_create = function(message, reply) {
  var id, ws;
  id = forge.tools.UUID();
  ws = new WebSocket(message.params.url);
  ws.eventQueue = [];
  ws.onmessage = (function(_this) {
    return function(event) {
      var pending;
      forge.logging.info('websocket [' + id + '] onmessage');
      if (ws.pollPending) {
        pending = ws.pollPending;
        ws.pollPending = null;
        return pending.reply({
          callid: pending.callid,
          status: 'success',
          content: {
            type: 'onmessage',
            data: event.data,
            readyState: ws.readyState
          }
        });
      } else {
        return ws.eventQueue.push({
          type: 'onmessage',
          data: event.data,
          readyState: ws.readyState
        });
      }
    };
  })(this);
  ws.onopen = (function(_this) {
    return function() {
      var pending;
      forge.logging.info('websocket [' + id + '] onopen');
      if (ws.pollPending) {
        pending = ws.pollPending;
        ws.pollPending = null;
        return pending.reply({
          callid: pending.callid,
          status: 'success',
          content: {
            type: 'onopen',
            readyState: ws.readyState
          }
        });
      } else {
        return ws.eventQueue.push({
          type: 'onopen',
          readyState: ws.readyState
        });
      }
    };
  })(this);
  ws.onclose = (function(_this) {
    return function() {
      var pending;
      forge.logging.info('websocket [' + id + '] onclose');
      if (ws.pollPending) {
        pending = ws.pollPending;
        ws.pollPending = null;
        return pending.reply({
          callid: pending.callid,
          status: 'success',
          content: {
            type: 'onclose',
            readyState: ws.readyState
          }
        });
      } else {
        return ws.eventQueue.push({
          type: 'onclose',
          readyState: ws.readyState
        });
      }
    };
  })(this);
  ws.onerror = (function(_this) {
    return function() {
      var pending;
      forge.logging.info('websocket [' + id + '] onerror');
      if (ws.pollPending) {
        pending = ws.pollPending;
        ws.pollPending = null;
        return pending.reply({
          callid: pending.callid,
          status: 'success',
          content: {
            type: 'onerror',
            readyState: ws.readyState
          }
        });
      } else {
        return ws.eventQueue.push({
          type: 'onerror',
          readyState: ws.readyState
        });
      }
    };
  })(this);
  websockets[id] = ws;
  return reply({
    callid: message.callid,
    status: 'success',
    content: {
      id: id
    }
  });
};

websocket_poll_event = (function(_this) {
  return function(message, reply) {
    var id, ws;
    id = message.params.id;
    ws = websockets[id];
    if (ws) {
      if (ws.eventQueue.length > 0) {
        return reply({
          callid: message.callid,
          status: 'success',
          content: ws.eventQueue.shift()
        });
      } else if (ws.pollPending) {
        return reply({
          callid: message.callid,
          status: 'error',
          content: {
            status: 'PoolEvent Request is exists'
          }
        });
      } else {
        return ws.pollPending = {
          callid: message.callid,
          reply: reply
        };
      }
    } else {
      return reply({
        callid: message.callid,
        status: 'error',
        content: {
          status: 'WebSocket does not exists'
        }
      });
    }
  };
})(this);

websocket_send = function(message, reply) {
  var id, ws;
  id = message.params.id;
  ws = websockets[id];
  if (ws) {
    console.log(typeof message.params.data);
    console.log(message.params.data);
    ws.send(message.params.data);
    return reply({
      callid: message.callid,
      status: 'success'
    });
  } else {
    return reply({
      callid: message.callid,
      status: 'error',
      content: {
        status: 'WebSocket does not exists'
      }
    });
  }
};

xhrs = {};

xhr_create = (function(_this) {
  return function(message, reply) {
    var id, xhr;
    id = forge.tools.UUID();
    xhr = new XMLHttpRequest(message.params);
    xhr.eventQueue = [];
    xhrs[id] = xhr;
    xhr.onreadystatechange = function() {
      var evt, pending;
      evt = {
        type: 'onreadystatechange',
        readyState: xhr.readyState
      };
      if (xhr.readyState === 0) {

      } else if (xhr.readyState === 1) {

      } else {
        evt.status = xhr.status;
        evt.statusText = xhr.statusText;
        evt.responseHeaders = xhr.getAllResponseHeaders();
        if (xhr.readyState === 2) {

        } else if (xhr.readyState === 3) {

        } else if (xhr.readyState === 4) {
          evt.responseText = xhr.responseText;
        }
      }
      if (xhr.pollPending) {
        pending = xhr.pollPending;
        xhr.pollPending = null;
        return pending.reply({
          callid: pending.callid,
          status: 'success',
          content: evt
        });
      } else {
        return xhr.eventQueue.push(evt);
      }
    };
    return reply({
      callid: message.callid,
      status: 'success',
      content: {
        id: id
      }
    });
  };
})(this);

xhr_open = (function(_this) {
  return function(message, reply) {
    var id, xhr;
    id = message.params.id;
    xhr = xhrs[id];
    if (xhr) {
      xhr.open(message.params.method, message.params.url, true);
      return reply({
        callid: message.callid,
        status: 'success',
        content: {
          id: id
        }
      });
    } else {
      return reply({
        callid: message.callid,
        status: 'error',
        content: {
          status: 'XHR does not exists'
        }
      });
    }
  };
})(this);

xhr_poll_event = (function(_this) {
  return function(message, reply) {
    var id, xhr;
    id = message.params.id;
    xhr = xhrs[id];
    if (xhr) {
      if (xhr.eventQueue.length > 0) {
        return reply({
          callid: message.callid,
          status: 'success',
          content: xhr.eventQueue.shift()
        });
      } else if (xhr.pollPending) {
        return reply({
          callid: message.callid,
          status: 'error',
          content: {
            status: 'PoolEvent Request is exists'
          }
        });
      } else {
        return xhr.pollPending = {
          callid: message.callid,
          reply: reply
        };
      }
    } else {
      return reply({
        callid: message.callid,
        status: 'error',
        content: {
          status: 'XHR does not exists'
        }
      });
    }
  };
})(this);

xhr_send = (function(_this) {
  return function(message, reply) {
    var id, xhr;
    id = message.params.id;
    xhr = xhrs[id];
    if (xhr) {
      xhr.send(message.params.data);
      return reply({
        callid: message.callid,
        status: 'success',
        content: {
          id: id
        }
      });
    } else {
      return reply({
        callid: message.callid,
        status: 'error',
        content: {
          status: 'XHR does not exists'
        }
      });
    }
  };
})(this);

xhr_set_request_header = (function(_this) {
  return function(message, reply) {
    var id, xhr;
    id = message.params.id;
    xhr = xhrs[id];
    if (xhr) {
      xhr.setRequestHeader(message.params.header, message.params.value);
      return reply({
        callid: message.callid,
        status: 'success',
        content: {
          id: id
        }
      });
    } else {
      return reply({
        callid: message.callid,
        status: 'error',
        content: {
          status: 'XHR does not exists'
        }
      });
    }
  };
})(this);

callback = (function(_this) {
  return function(message, reply) {
    if (message.method !== 'http:get') {
      forge.logging.info(message);
    }
    if (message.method === 'http:get') {
      return http_get(message, reply);
    } else if (message.method === 'http:post') {
      return http_post(message, reply);
    } else if (message.method === 'ws:create') {
      return websocket_create(message, reply);
    } else if (message.method === 'ws:poll-event') {
      return websocket_poll_event(message, reply);
    } else if (message.method === 'ws:send') {
      return websocket_send(message, reply);
    } else if (message.method === 'xhr:create') {
      return xhr_create(message, reply);
    } else if (message.method === 'xhr:poll-event') {
      return xhr_poll_event(message, reply);
    } else if (message.method === 'xhr:open') {
      return xhr_open(message, reply);
    } else if (message.method === 'xhr:send') {
      return xhr_send(message, reply);
    } else if (message.method === 'xhr:set-request-header') {
      return xhr_set_request_header(message, reply);
    }
  };
})(this);

error = (function(_this) {
  return function(content) {
    return forge.logging.error(content);
  };
})(this);

forge.message.listen("message", callback, error);



},{}]},{},[1]);
