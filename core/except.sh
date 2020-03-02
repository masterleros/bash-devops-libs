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

#!/bin/bash

function exceptOnError() {
    # Get the exit code and raise the exception if needed
    local _errorCode=${?}
    [ "${_errorCode}" == 0 ] || raise ${_errorCode} 1

    # Return the exit code
    return ${_errorCode}
}

function raise() {
    local _errorCode=${1}
    local _errIndex=${2}
    [ "_errIndex" ] || _errIndex=0
    echoError "Exception at '${BASH_SOURCE["${_errIndex}"]}' - line ${BASH_LINENO["${_errIndex}"]} (code: ${_errorCode})"
    kill -SIGTERM $$
}

function try() {

    # Function when catch the try
    function tryCatch() {
        # Unset the trap
        trap - SIGTERM
        echoError "Exception catch!"
    }
    
    # Set thy trap
    eval "trap 'tryCatch' SIGTERM"

    # Execute the provided command
    ${@}
}