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

### INTERNAL FUNCTION ###
# Empty function that receives the function/code rework from
# core modules functions __rework()
### INTERNAL FUNCTION ###
function _dolibReworkCode() {
    ${PLUGIN_PLACEHOLDER}
}

### INTERNAL FUNCTION ###
# Import a core module
### INTERNAL FUNCTION ###
function _dolibImportModule() {

    # Import the module
    . "${1}"

    # If the __rework function exist
    if [ "$(declare -F __rework)" ]; then

        # Get the rework function from the module
        local newCode=$(declare -f __rework | tail -n +3 | head -n -1)

        # Get current rework code
        local funcCode=$(declare -f _dolibReworkCode | tail -n +3 | head -n -1)
        # Redeclare the function with the  new modules rework code
        eval "$(echo "_dolibReworkCode() {"; echo "${funcCode/'${PLUGIN_PLACEHOLDER}'/"${newCode}"';${PLUGIN_PLACEHOLDER}'}"; echo "}")"

        # Unset the module rework function    
        unset -f __rework

        # Export the new function for sub-processes
        export -f _dolibReworkCode
    fi
}

# @description Rework a function to enable dolibs features
# @arg $func string Current function name
# @arg $newFunc string (optional) New function name in case of renaming
# @example
#   dolibReworkFunction <func> <newFunc>
function dolibReworkFunction() {

    local _funct=${1}
    local _newFunc=${2}
    local _file=${_libEntryPoint:-${BASH_SOURCE[-1]}}

    # If no new function name is given, use the current one
    [ "${_newFunc}" ] || _newFunc="${_funct}"

    # Get function content
    local _body=$(declare -f "${_funct}" | tail -n +3 | head -n -1)

    # if no body, exit with error
    [ "${_body}" ] || exitOnError "Function '${_funct}' does not exist"
    
    # Execute the modules rework
    _dolibReworkCode

    # Export the reworked function
    eval "$(echo "${_newFunc}() {"; echo "${_body}"; echo "}")"

    # Unset old function name if is different than original
    [ "${_funct}" == "${_newFunc}" ] || unset -f "${_funct}"

    # Export the new function for sub-processes
    export -f "${_newFunc}"

    # Debug
    #echo "Reworked function:  ${_libFunct} -> ${_libFunctNew}()"    
}

# @description Import a library (this function is not intended to be used manually, instead use do.use or do.import)
# @arg $lib string Library namespace
# @arg $libEntryPoint path Path to lib entrypoint sh file
# @example
#   dolibImportLib <lib> <libEntryPoint>
function dolibImportLib() {

    local _lib=${1}
    local _libEntryPoint=${2}

    # Check the lib entrypoint    
    [ -f "${_libEntryPoint}" ] || exitOnError "It was not posible to find '${_lib}' entrypoint at '${_libEntryPoint}'"
    local _libDir=$(dirname "${_libEntryPoint}")

    # Get current funcions
    local _currFuncts=$(typeset -F)

    # Import lib
    local SELF_LIB="${_lib}"
    local SELF_LIB_DIR="${_libDir}"
    source "${_libEntryPoint}"
    exitOnError "Error importing '${_libEntryPoint}'"

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