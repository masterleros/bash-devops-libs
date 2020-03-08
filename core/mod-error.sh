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

# Rework imported code
function __rework() {
    # returnOnError
    _body=${_body//returnOnError/local _eCode='${?}'; [ '${_eCode}' == 0 ] || return '${_eCode}'}    
}

### Exit program with text when last exit code is non-zero ###
# usage: exitOnError <output_message> [optional: forced code (defaul:exit code)]
function exitOnError() {
    local _errorCode=${2:-$?}
    local _errorText=${1}

    # If there is an error
    if [ "${_errorCode}" -ne 0 ]; then

        # If it is in a try context
        if [ "${DOLIB_TRY_CONTEXT}" != "true" ]; then    
            if [ ! -z "${_errorText}" ]; then
                echoError "${_errorText}\nExiting (${_errorCode})..."
            else
                echoError "At '${BASH_SOURCE[-1]}' (Line ${BASH_LINENO[-2]})\nExiting (${_errorCode})..."
            fi
        fi

        exit "${_errorCode}"
    fi
}
