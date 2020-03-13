#!/bin/bash
#    Copyright 2020 Leonardo Andres Morales

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

echoInfo "I am the '${SELF_LIB}' lib and I am being loading..."

function doSome() {
    getArgs "var"
    echoInfo "Hey! I have received the value: ${var}"
    _return="Something done!"
}

echoInfo "Nice! I was completely loaded"
