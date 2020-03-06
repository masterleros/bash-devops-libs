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

DOLIB_EXCEPTION_CATCH=""

#  https://stackoverflow.com/questions/22009364/is-there-a-try-catch-command-in-bash

# Set execution when an exception is raised
function catch() {
    DOLIB_EXCEPTION_CATCH=("${@}")
}

# Raise an exception
function raise() {
    local _eCode=${?}
    if [ "${_eCode}" != 0 ]; then
        [ "${DOLIB_EXCEPTION_CATCH}" ] && \
        [ "$(trap -- | grep tryCatch)" ] || \
            echoError "Unhandled exception at '${BASH_SOURCE[-1]}' - line ${BASH_LINENO[-2]} (code: ${_eCode})"
        kill -SIGTERM ${$}
    fi
    return ${_eCode}
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

    # Execute the command
    ${@}
}
