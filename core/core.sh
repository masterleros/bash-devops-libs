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

### Empty function that receives the function/code 
#content to be reworked
function dolibReworkCode() {
    ${PLUGIN_PLACEHOLDER}
}

### Import a module
function dolibImportModule() {

    # Import the module
    . "${1}"

    # If the __rework function exist
    if [ "$(declare -F __rework)" ]; then

        # Get the rework function from the module
        local newCode=$(declare -f __rework | tail -n +3 | head -n -1)

        # Get current rework code
        local funcCode=$(declare -f dolibReworkCode | tail -n +3 | head -n -1)
        # Redeclare the function with the  new modules rework code
        eval "$(echo "dolibReworkCode() {"; echo "${funcCode/'${PLUGIN_PLACEHOLDER}'/"${newCode}"';${PLUGIN_PLACEHOLDER}'}"; echo "}")"

        # Unset the module rework function    
        unset -f __rework

        # Export the new function for sub-processes
        export -f dolibReworkCode
    fi
}

### Rework a function
# Usage: dolibReworkFunction <_funct> [_newFunc]
# obs: _newFunc is optional in case of changing its name
function dolibReworkFunction() {

    local _funct=${1}
    local _newFunc=${2}

    # If no new function name is given, use the current one
    [ "${_newFunc}" ] || _newFunc="${_funct}"

    # Get function content
    local body=$(declare -f "${_funct}" | tail -n +3 | head -n -1)

    # if no body, exit with error
    [ "${body}" ] || exitOnError "Function '${_funct}' does not exist"
    
    # Execute the modules rework
    dolibReworkCode

    # Export the reworked function
    eval "$(echo "${_newFunc}() {"; echo "${_funcHeader}"; echo "${body}"; echo "}")"

    # Unset old function name if is different than original
    [ "${_funct}" == "${_newFunc}" ] || unset -f "${_funct}"

    # Export the new function for sub-processes
    export -f "${_newFunc}"

    # Debug
    #echo "Reworked function:  ${_libFunct} -> ${_libFunctNew}()"    
}

### Consume an internal library ###
# Usage: dolibCreateLibFunctions <_lib> <lib_dir>
function dolibCreateLibFunctions() {

    local _lib=${1}
    local _libDir=${2}

    # Set the function local context, this is required because    
    # these values can be used when sourcing the new lib code
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
    fi'
    ############################

    # Check the lib entrypoint
    local _libEntrypoint=${_libDir}/${DOLIBS_MAIN_FILE}
    [ -f "${_libEntrypoint}" ] || exitOnError "It was not posible to find '${_lib}' entrypoint at '${_libEntrypoint}'"

    # Get current funcions
    local _currFuncts=$(typeset -F)

    # Import lib
    source "${_libEntrypoint}"
    exitOnError "Error importing '${_libEntrypoint}'"

    # Get new functions
    local _libFuncts=($((typeset -F; echo "${_currFuncts}") | sort | uniq -u | awk '{print $NF}'))

    # Rename functions
    _return=0
    for _libFunct in ${_libFuncts[@]}; do

        # Remove last functions
        for _currFunct in ${_currFuncts[@]}; do 
            _libFuncts=("${_libFuncts[@]/^${_currFunct}*/}"); 
        done

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