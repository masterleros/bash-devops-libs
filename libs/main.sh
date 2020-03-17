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

### Import DevOps Lib files ###
# Usage: _importLibFiles <lib>
function _importLibFiles() {
    
    getArgs "_lib _libPath _libTmpPath _libTmpMain" "${@}"

    # Check if the lib is available from download
    if [ -f ${_libTmpMain} ]; then
        # Create lib dir and copy
        mkdir -p ${_libPath} && cp -r ${_libTmpPath}/* ${_libPath}
        exitOnError "Could not copy the '${_lib}' library files"
        return 0        
    fi
    
    echoError "DEVOPS Library '${_lib}' not found! (was it downloaded already?)"
    return 1
}

### Check if a value exists in an array ###
# usage: _valueInArray <value> <array>
function _valueInArray() {
    getArgs "_value &@_values" "${@}"
    local _val
    for _val in "${_values[@]}"; do
        if [[ "${_val}" == "${_value}" ]]; then return 1; fi
    done
    return 0
}

### Set the context for a function
# usage: _setContext <namespace>.<funcName>
function _setContext() {
    # Set context vars
    local CURRENT_LIB=${FUNCNAME%.*}; CURRENT_LIB=${CURRENT_LIB#*.}
    local CURRENT_LIB_FUNC=${FUNCNAME##*.}
    local CURRENT_LIB_DIR=${DOLIBS_DIR}/${CURRENT_LIB/./\/}
    # echo "Set context for ${1} (lib: ${CURRENT_LIB} - func: ${CURRENT_LIB_FUNC} - dir: ${CURRENT_LIB_DIR})"
}

### Import DevOps Libs ###
# Usage: import <lib1> <lib2> ... <libN>
function import() {

    # local CURRENT_LIB_FUNC=${FUNCNAME##*.}
    local _libContext='local CURRENT_LIB=${FUNCNAME%.*}; CURRENT_LIB=${CURRENT_LIB#*.};
                    local CURRENT_LIB_DIR=${DOLIBS_DIR}/${CURRENT_LIB/./\/}'

    # For each lib
    local _result=0
    while [ "${1}" ]; do
        local _lib="${1}"
        local _libDir=${_lib//./\/}
        local _libPath=${DOLIBS_DIR}/${_libDir}
        local _libMain=${_libPath}/${DOLIBS_MAIN_FILE}
        local _libTmpPath=${DOLIBS_TMP_DIR}/libs/${_libDir}
        local _libTmpMain=${_libTmpPath}/${DOLIBS_MAIN_FILE}

        # if lib was already imported
        #self _valueInArray ${_lib} "${DOLIBS_IMPORTED[@]}"
        echo "${DOLIBS_IMPORTED}" | tr ';' '\n' | grep "^${_lib}\$" > /dev/null
        if [ ${?} == 0 ]; then
            echoInfo "Library '${_lib}' already imported!"
        else
            # Check if it is in online mode to copy/update libs
            if [[ "${DOLIBS_MODE}" == "online" || "${DOLIBS_MODE}" == "local" ]]; then
                # Include the lib
                self _importLibFiles ${_lib} ${_libPath} ${_libTmpPath} ${_libTmpMain}
                exitOnError "It was not possible to import the library files '${_libTmpPath}'"
            # Check if the lib is available locally
            elif [ ! -f "${_libMain}" ]; then
                # In in auto mode
                if [[ ${DOLIBS_MODE} == "auto" && ! -f "${_libTmpMain}" ]]; then
                    echoInfo "AUTO MODE - '${_lib}' is not installed neither found in cache, cloning code"

                    # Try to clone the lib code                
                    devOpsLibsClone
                    exitOnError "It was not possible to clone the library code"
                fi

                # Include the lib
                self _importLibFiles ${_lib} ${_libPath} ${_libTmpPath} ${_libTmpMain}
                exitOnError "It was not possible to import the library files '${_libTmpPath}'"
            fi

            # Check if there was no error importing the lib files
            if [ ${?} -eq 0 ]; then
                # Import lib
                source ${DOLIBS_LIB_FILE} ${_lib} ${_libPath}
                exitOnError "Error importing '${_libMain}'"

                # Get lib function names
                local _libFuncts=($(bash -c '. '"${DOLIBS_LIB_FILE} ${_lib} ${_libPath}"' &> /dev/null; typeset -F' | awk '{print $NF}'))

                # Create the functions
                _createLibFunctions ${_lib} "${_libContext}" ${_libFuncts[@]}
            else 
                ((_result+=1)); 
            fi

            # Set as imported
            export DOLIBS_IMPORTED="${DOLIBS_IMPORTED};${_lib}"

            # Show import
            echoInfo "Imported Library '${_lib}' (${_funcCount} functions)"
        fi

        # Go to next arg
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "Some DevOps Libraries were not found!" ${_result}
}