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

echoDebug "I am the '${SELF_LIB}' lib and I am being loading..."
echoDebug "${SELF_LIB}: Doing something..."

# Check if dependencies are in place
checkBins uptime || return ${?}

# @description Print the computer uptime
# @arg $var string Any value to be shown
function doIt() {
    getArgs "var" "${@}"
    echoTitle "Hello from '${SELF_LIB}' lib!"
    echoInfo "You have provided the the value '${var}'
I'm running from '${SELF_LIB_DIR}'
and current up-time is: $(uptime -p)"
}

# @description Exit with error for purpouse of demostrate try functionality
function breakIt() {
    echoInfo "${FUNCNAME}(): I am a problematic function and will break now"
    exitOnError "${FUNCNAME}(): I told you!" 1
}

echoDebug "${SELF_LIB}: I've ended loading my resources!"
