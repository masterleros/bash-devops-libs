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

# @description Try execution in a subshel so that will not exit the program in case of failure
# @arg $@ list Command to be executed
# @exitcode last Last execution exit code
# @example
#   try <command>
try() {

    # Manage set -e
    local _setE=${-//[^e]/}
    set +"${_setE}"

    # If it is an assigment
    if [ "${1}" == "assign" ]; then            
        local _tmpFile="${DOLIBS_TMPDIR}/.try-${RANDOM}.tmp"
        local _assigments=${2}
        local _returnVar=${_assigments%%"="*}
        local _returnFunc=${_assigments##*"="}        
        shift 2

        # Remove tmp file if exists
        [ -f "${_tmpFile}" ] && rm "${_tmpFile}"

        (
            # Execute the actual function
            ${_returnFunc} "${@}"
            declare | egrep ^_return= | cut -d '=' -f2- > "${_tmpFile}"
        )
        local _result=${?}
    
        # Restore the value if was written
        [ -f "${_tmpFile}" ] && eval "${_returnVar}"=$(cat "${_tmpFile}")

    # If is a normal function
    else
        (
        "${@}"
        )
        local _result=${?}
    fi

    # Show message
    [ "${_result}" == 0 ] || echoWarn "Caught exception At '${BASH_SOURCE[-1]}' (Line ${BASH_LINENO[-2]})"

    # put back set -e in case it was set before
    set -"${_setE}"

    return ${_result}
}
