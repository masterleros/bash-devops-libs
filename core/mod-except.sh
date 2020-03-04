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
DOLIB_EXCEPTION_CATCH=""

#  https://stackoverflow.com/questions/22009364/is-there-a-try-catch-command-in-bash

# Rework imported code
function __rework() {
    # rework function content
    body=${body//raiseOnError/local _eCode='${?}'; [ '${_eCode}' == 0 ] || raise '${_eCode}' && return '${_eCode}'}
}


# Raise an exception in case of an error
# function raiseOnError() {
#     local _errorCode=${?}
#     [ "${_errorCode}" == 0 ] || raise ${_errorCode} 1
#     return ${_errorCode}
# }

# Set execution when an exception is raised
function catch() {
    DOLIB_EXCEPTION_CATCH=("${@}")
}

# Raise an exception
function raise() {
    local _errorCode=${?}
    local _errIndex=${1}
    [ "${_errIndex}" ] || _errIndex=0
    [ "${DOLIB_EXCEPTION_CATCH}" ] && [ "$(trap -- | grep tryCatch)" ] || \
        echoError "Unhandled exception at '${BASH_SOURCE["${_errIndex}"]}' - line ${BASH_LINENO["${_errIndex}"]} (code: ${_errorCode})"
    kill -SIGTERM ${$}
    return ${_errorCode}
}

# Catch execution in the exception
function try() {

    # Function when catch the try
    function tryCatch() {
        # Execute the exception code
        if [ "${DOLIB_EXCEPTION_CATCH}" ]; then
            "${DOLIB_EXCEPTION_CATCH[@]}"
            unset -v DOLIB_EXCEPTION_CATCH
        fi

        # Unset the trap
        trap - SIGTERM        
    }
    
    # Set thy trap
    trap tryCatch SIGTERM
}