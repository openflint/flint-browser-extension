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

websockets = {}

callback = (message, reply) =>
    forge.logging.info message

    # message {
    #     callid: callid
    #     method: method
    #     params: params
    # }
    if message.method is 'http:get'
        # Use the REST api to request more information about this service
        xhr = new XMLHttpRequest()
        xhr.open "GET", message.params.url, true

        if message.params.headers
            for key in payload.headers
                xhr.setRequestHeader key, message.params.headers[key]

        listener = =>
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

        xhr.addEventListener "load", listener, false
        xhr.send null

    else if message.method is 'http:post'
        # Use the REST api to request more information about this service
        xhr = new XMLHttpRequest()
        xhr.open "POST", message.params.url, true

        if message.params.headers
            for key in payload.headers
                xhr.setRequestHeader key, message.params.headers[key]

        listener = =>
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

        xhr.addEventListener "load", listener, false
        xhr.send message.params.data

        # { callid: 1,
        #   method: 'websocket:create',
        #   params: { url: 'ws://192.168.1.173:8080/channels/demo' } }

    else if message.method is 'websocket:create'
        id = forge.tools.UUID()

        ws = new WebSocket message.params.url
        ws.pendings = []
        ws.messages = []
        ws.onmessage = (event) =>
            if ws.pendings.length > 0
                pending = ws.pendings.shift()
                pending.reply
                    callid: pending.message.callid
                    status: 'success'
                    content:
                        data: [ event.data ]
            else
                ws.messages.push event.data

        websockets[id] = ws

        reply
            callid: message.callid
            status: 'success'
            content:
                id: id

    else if message.method is 'websocket:get-message'
        id = message.params.id
        ws = websockets[id]
        if ws
            if ws.messages
                if ws.messages.length > 0
                    reply
                        callid: message.callid
                        status: 'success'
                        content:
                            data: ws.messages
                    ws.messages = []
                else
                    ws.pendings.push
                        message: message,
                        reply: reply
            else
                if ws.readyState == 2 or ws.readyState == 3
                    reply
                        callid: message.callid
                        status: 'error'
                        content:
                            status: 'closed'

    else if message.method is 'websocket:send-message'
        id = message.params.id
        ws = websockets[id]
        if ws
            ws.send message.params.data
            reply
                callid: message.callid
                status: 'success'

error = (content) =>
    forge.logging.error content

forge.message.listen "message", callback, error


