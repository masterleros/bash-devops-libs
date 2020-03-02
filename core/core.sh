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

### Rework a function
# Usage: dolibReworkFunction <_funct> [_newFunc]
# obs: _newFunc is optional in case of changing its name
function dolibReworkFunction() {

    getArgs "_funct &_newFunc" "${@}"

    ### NEW ###
    # Get function content
    local _funcBody=$(declare -f  ${_funct} | tail -n +3 | head -n -1)

    # rework function content
    _funcBody=${_funcBody//exceptOnError/local _eCode='${?}'; [ '${_eCode}' == 0 ] || raise '${_eCode}' && return '${_eCode}'}

    # Reasembly the function
    [ "${_newFunc}" ] || _newFunc="${_funct}"
    local _funcDeclare=$(echo "${_newFunc}() {"; echo "${_funcHeader}"; echo "${_funcBody}"; echo })

    # Export the reworked function
    eval "${_funcDeclare}"

    # Unset old function name
    [ "${_funct}" == "${_newFunc}" ] || unset -f "${_funct}"

    # Export the new function for sub-processes
    export -f "${_newFunc}"

    # Debug
    #echo "Reworked function:  ${_libFunct} -> ${_libFunctNew}()"    
}

### Consume an internal library ###
# Usage: dolibCreateLibFunctions <_lib> <lib_dir>
function dolibCreateLibFunctions() {

    getArgs "_lib _libDir" "${@}"

    # Set the function local context
    local SELF_LIB="${_lib}"
    local SELF_LIB_DIR="${_libDir}"
    local _funcHeader='
local SELF_LIB='${SELF_LIB}'
local SELF_LIB_DIR='${SELF_LIB_DIR}'
if [ ${-//[^e]/} ]; then 
    set +e
    ${FUNCNAME} "${@}"
    _result=${?}
    set -e
    return ${_result}
fi
'

    # Check the lib entrypoint
    local _libEntrypoint=${_libDir}/${DOLIBS_MAIN_FILE}
    [ -f "${_libEntrypoint}" ] || exitOnError "It was not posible to find '${_lib}' entrypoint at '${_libEntrypoint}'"

    # Get current funcions
    local _currFuncts=($(typeset -F | awk '{print $NF}'))

    # Import lib
    source "${_libEntrypoint}"
    exitOnError "Error importing '${_libEntrypoint}'"

    # Get new functions
    local _libFuncts=($(typeset -F | awk '{print $NF}'))

    # Remove last functions
    for _currFunct in ${_currFuncts[@]}; do _libFuncts=("${_libFuncts[@]/${_currFunct}}"); done

    # Rename functions
    _return=0
    for _libFunct in ${_libFuncts[@]}; do
        # If function is not already imported
        if [[ ${_libFunct} != *"."* ]]; then
            # New lib name
            _libFunctNew=${_lib}.${_libFunct##*.}

            # Rework the function
            dolibReworkFunction "${_libFunct}" "${_libFunctNew}"

    
            ((_return+=1))
        fi
    done
}