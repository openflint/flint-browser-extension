#
# Copyright (C) 2013-2014, The OpenFlint Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

forge.logging.info "Flint extension background script is running !"

###############################################################################
#
# HTTP
#
###############################################################################

http_get = (message, reply) ->
    # Use the REST api to request more information about this service
    xhr = new XMLHttpRequest()
    xhr.open "GET", message.params.url, true

    if message.params.headers
        for key in message.params.headers
            xhr.setRequestHeader key, message.params.headers[key]

    xhr.onreadystatechange = =>
        if xhr.readyState == 4
            if 200 <= xhr.status < 300
                reply
                    callid: message.callid
                    status: 'success'
                    content:
                        status: xhr.status
                        data: xhr.responseText
            else
                reply
                    callid: message.callid
                    status: 'error'
                    content:
                        status: xhr.status
    xhr.send null

http_post = (message, reply) ->
    # Use the REST api to request more information about this service
    xhr = new XMLHttpRequest()
    xhr.open "POST", message.params.url, true
    forge.logging.info "POST_URL : " + message.params.url

    if message.params.headers
        for key in message.params.headers
            forge.logging.info key + " : " + message.params.headers[key]
            xhr.setRequestHeader key, message.params.headers[key]

    xhr.onreadystatechange = =>
        if xhr.readyState == 4
            if 200 <= xhr.status < 300
                reply
                    callid: message.callid
                    status: 'success'
                    content:
                        status: xhr.status
                        data: xhr.responseText
            else
                reply
                    callid: message.callid
                    status: 'error'
                    content:
                        status: xhr.status

    if typeof message.params.data == 'string'
        xhr.send message.params.data
    else
        xhr.send JSON.stringify(message.params.data)

###############################################################################
#
# WebSocket
#
###############################################################################

websockets = {}

websocket_create = (message, reply) ->
    id = forge.tools.UUID()

    ws = new WebSocket message.params.url
    ws.eventQueue = []

    ws.onmessage = (event) =>
        forge.logging.info 'websocket [' + id + '] onmessage'
        # forge.logging.info event.data

        if ws.pollPending
            pending = ws.pollPending
            ws.pollPending = null

            pending.reply
                callid: pending.callid
                status: 'success'
                content:
                    type: 'onmessage'
                    data: event.data
                    readyState: ws.readyState
        else
            ws.eventQueue.push
                type: 'onmessage'
                data: event.data
                readyState: ws.readyState

    ws.onopen = =>
        forge.logging.info 'websocket [' + id + '] onopen'

        if ws.pollPending
            pending = ws.pollPending
            ws.pollPending = null

            pending.reply
                callid: pending.callid
                status: 'success'
                content:
                    type: 'onopen'
                    readyState: ws.readyState
        else
            ws.eventQueue.push
                type: 'onopen'
                readyState: ws.readyState

    ws.onclose = =>
        forge.logging.info 'websocket [' + id + '] onclose'
        if ws.pollPending
            pending = ws.pollPending
            ws.pollPending = null

            pending.reply
                callid: pending.callid
                status: 'success'
                content:
                    type: 'onclose'
                    readyState: ws.readyState
        else
            ws.eventQueue.push
                type: 'onclose'
                readyState: ws.readyState

    ws.onerror = =>
        forge.logging.info 'websocket [' + id + '] onerror'
        if ws.pollPending
            pending = ws.pollPending
            ws.pollPending = null

            pending.reply
                callid: pending.callid
                status: 'success'
                content:
                    type: 'onerror'
                    readyState: ws.readyState
        else
            ws.eventQueue.push
                type: 'onerror'
                readyState: ws.readyState

    websockets[id] = ws

    reply
        callid: message.callid
        status: 'success'
        content:
            id: id
#
# { callid: 1,
#   method: 'websocket:poll-event' }
#
websocket_poll_event = (message, reply) =>
    id = message.params.id
    ws = websockets[id]

    if ws
        if ws.eventQueue.length > 0
            reply
                callid: message.callid
                status: 'success'
                content: ws.eventQueue.shift()

        else if ws.pollPending
            reply
                callid: message.callid
                status: 'error'
                content:
                    status: 'PoolEvent Request is exists'

        else
            ws.pollPending =
                callid: message.callid
                reply: reply
    else
        reply
            callid: message.callid
            status: 'error'
            content:
                status: 'WebSocket does not exists'

websocket_send = (message, reply) ->
    id = message.params.id
    ws = websockets[id]
    if ws
        console.log (typeof message.params.data);
        console.log (message.params.data);
        ws.send(message.params.data)
        reply
            callid: message.callid
            status: 'success'
    else
        reply
            callid: message.callid
            status: 'error'
            content:
                status: 'WebSocket does not exists'

###############################################################################
#
# XMLHttpRequest
#
# TODO: xhr:poll-event 事件泵，可以用来维系生命周期
#
###############################################################################

xhrs = {}

#
# { callid: 1,
#   method: 'xhr:create',
#   params: xxx
# }

xhr_create = (message, reply) =>
    id = forge.tools.UUID()

    xhr = new XMLHttpRequest(message.params)
    xhr.eventQueue = []

    xhrs[id] = xhr

    xhr.onreadystatechange = =>
        evt =
            type: 'onreadystatechange'
            readyState: xhr.readyState

        if xhr.readyState == 0 # UNSENT open()has not been called yet.
            # ignore
        else if xhr.readyState == 1 # OPENED send() has not been called yet.
            # ignore
        else
            evt.status = xhr.status
            evt.statusText = xhr.statusText
            evt.responseHeaders = xhr.getAllResponseHeaders()

            if xhr.readyState == 2 # HEADERS_RECEIVED send() has been called, and headers and status are available.
                # ignore
            else if xhr.readyState == 3 # LOADING Downloading; responseText holds partial data.
                # ignore partial data
            else if xhr.readyState == 4 # DONE The operation is complete.
                evt.responseText = xhr.responseText

        if xhr.pollPending
            pending = xhr.pollPending
            xhr.pollPending = null
            pending.reply
                callid: pending.callid
                status: 'success'
                content: evt
        else
            xhr.eventQueue.push evt

    reply
        callid: message.callid
        status: 'success'
        content:
            id: id

#
# { callid: 1,
#   method: 'xhr:open',
#   params: {
#     method: 'GET' or 'POST',
#     url: 'http://www.163.com',
#   }
# }
#
xhr_open = (message, reply) =>
    id = message.params.id
    xhr = xhrs[id]

    if xhr
        xhr.open(message.params.method, message.params.url, true)
        reply
            callid: message.callid
            status: 'success'
            content:
                id: id
    else
        reply
            callid: message.callid
            status: 'error'
            content:
                status: 'XHR does not exists'

#
# { callid: 1,
#   method: 'xhr:poll-event',
#   params: {
#     method: 'GET' or 'POST',
#     url: 'http://www.163.com',
#   }
# }

xhr_poll_event = (message, reply) =>
    id = message.params.id
    xhr = xhrs[id]

    if xhr
        if xhr.eventQueue.length > 0
            reply
                callid: message.callid
                status: 'success'
                content: xhr.eventQueue.shift()

        else if xhr.pollPending
            reply
                callid: message.callid
                status: 'error'
                content:
                    status: 'PoolEvent Request is exists'

        else
            xhr.pollPending =
                callid: message.callid
                reply: reply
    else
        reply
            callid: message.callid
            status: 'error'
            content:
                status: 'XHR does not exists'

#
# { callid: 1,
#   method: 'xhr:send',
#   params: {
#     data: 'xxxx'
#   }
# }
xhr_send = (message, reply) =>
    id = message.params.id
    xhr = xhrs[id]

    if xhr
        xhr.send(message.params.data)
        reply
            callid: message.callid
            status: 'success'
            content:
                id: id
    else
        reply
            callid: message.callid
            status: 'error'
            content:
                status: 'XHR does not exists'

#
# { callid: 1,
#   method: 'xhr:set-request-header',
#   params: {
#     header: 'xxxx',
#     value: 'yyyy'
#   }
# }
#
xhr_set_request_header = (message, reply) =>
    id = message.params.id
    xhr = xhrs[id]

    if xhr
        xhr.setRequestHeader(message.params.header, message.params.value)
        reply
            callid: message.callid
            status: 'success'
            content:
                id: id
    else
        reply
            callid: message.callid
            status: 'error'
            content:
                status: 'XHR does not exists'


callback = (message, reply) =>
    if message.method isnt 'http:get'
        forge.logging.info message

    # message {
    #     callid: callid
    #     method: method
    #     params: params
    # }

    #
    # HTTP
    #
    if message.method is 'http:get'
        http_get message, reply

    else if message.method is 'http:post'
        http_post message, reply

        #
        # WebSocket
        #
    else if message.method is 'ws:create'
        websocket_create message, reply

    else if message.method is 'ws:poll-event'
        websocket_poll_event message, reply

    else if message.method is 'ws:send'
        websocket_send message, reply

        #
        # XHR
        #
    else if message.method is 'xhr:create'
        xhr_create(message, reply)

    else if message.method is 'xhr:poll-event'
        xhr_poll_event(message, reply)

    else if message.method is 'xhr:open'
        xhr_open(message, reply)

    else if message.method is 'xhr:send'
        xhr_send(message, reply)

    else if message.method is 'xhr:set-request-header'
        xhr_set_request_header(message, reply)

error = (content) =>
    forge.logging.error content

forge.message.listen "message", callback, error


