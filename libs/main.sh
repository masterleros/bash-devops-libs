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
    local _pos=0
    for _val in "${_values[@]}"; do
        if [[ "${_val}" == "${_value}" ]]; then 
            _return=${_pos}
            return 0;
        fi
        ((_pos+=1))
    done
    return -1
}

### Import DevOps Libs ###
# Usage: import <lib1> <lib2> ... <libN>
function import() {

    # For each lib
    local _result=0
    while [ "${1}" ]; do
        
        # Current lib
        local _lib="${1}"
        local _libSpace=(${_lib//./ })
        local _libDir=${_lib/./\/}
        local _libPath=${DOLIBS_DIR}/${_libDir}
        local _libMain=${_libPath}/${DOLIBS_MAIN_FILE}

        # Check if it is a custom lib
        assign _customPos=self _valueInArray ${_libSpace} "${DOLIBS_CUSTOM_SPACE[@]}"                    
        if [[ ${?} -eq 0 ]]; then            
            local _gitRepo=${DOLIBS_CUSTOM_REPO[${_pos}]} 
            local _gitBranch=${DOLIBS_CUSTOM_BRANCH[${_pos}]}
            local _gitDir=${DOLIBS_CUSTOM_TMP_DIR[${_pos}]}
        else
            local _gitRepo=${DOLIBS_REPO}
            local _gitBranch=${DOLIBS_BRANCH}
            local _gitDir=${DOLIBS_TMP_DIR}
        fi

        # Lib main file
        local _libTmpPath=${_gitDir}/libs/${_libDir}
        local _libTmpMain=${_libTmpPath}/${DOLIBS_MAIN_FILE}

        # local CURRENT_LIB_FUNC=${FUNCNAME##*.}
        local _libContext='local CURRENT_LIB=${FUNCNAME%.*}; CURRENT_LIB=${CURRENT_LIB#*.};
                        local CURRENT_LIB_DIR='${DOLIBS_DIR}'/${CURRENT_LIB/./\/}'

        # if lib was already imported
        self _valueInArray ${_lib} "${DOLIBS_IMPORTED[@]}"
        if [[ ${?} -eq 0 ]]; then
            echoInfo "DEVOPS Library '${_lib}' already imported!"
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
                    echoInfo "AUTO MODE - '${_lib}' is not installed neither found in cache, cloning code..."

                    # Try to clone the lib code
                    devOpsLibsClone ${_gitRepo} ${_gitBranch} ${_gitDir}
                    
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
                _createLibFunctions ${_lib} "${_libContext}" ${_libFuncts}
            else 
                ((_result+=1)); 
            fi

            # Set as imported
            export DOLIBS_IMPORTED+=(${_lib})

            # Show import
            echoInfo "Imported Library '${_lib}' (${_funcCount} functions)"
        fi

        # Go to next arg
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "Some DevOps Libraries were not found!" ${_result}
}

# Function to add a custom lib repository source
# Usage: addCustomSource <names> <git_url> <optional_branch>
function addCustomSource() {
    getArgs "_name _url &_branch" "${@}"

    # Check if in local mode
    [[ ${DOLIBS_MODE} != 'local' ]] || exitOnError "Custom remote sources are not supported in local mode!"

    # Set default branch case not specified
    if [ ! "${_branch}" ]; then _branch="master"; fi
    
    # Add the custom repo
    local _pos=${#DOLIBS_CUSTOM_SPACE[@]}
    DOLIBS_CUSTOM_SPACE[${_pos}]="${_name}"
    DOLIBS_CUSTOM_REPO[${_pos}]="${_url}"
    DOLIBS_CUSTOM_BRANCH[${_pos}]="${_branch}"
    DOLIBS_CUSTOM_TMP_DIR[${_pos}]="${DOLIBS_DIR}/.libtmp/custom/${_name}/${_branch}"

    echoInfo "Added custom lib source '${_name}'"
}

