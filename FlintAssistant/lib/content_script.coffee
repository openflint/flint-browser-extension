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

forge.logging.info('FlintAssistant content-script is running ...');

window.addEventListener 'message', (event) =>

    message = event.data;

    # it is 3rd party message
    return if message?.to isnt 'content-script'

    return if typeof message.payload is undefined

    callback = (payload) =>
        # forward reply message to page
        window.postMessage {
            to: 'page-script'
            payload: payload
        }, '*'

    error = (error) =>
        console.error(error)

    # forward message to background script
    forge.message.broadcastBackground 'message', message.payload, callback, error
