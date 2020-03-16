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
    local CURRENT_LIB_DIR=${DEVOPS_LIBS_PATH}/${CURRENT_LIB/./\/}
    # echo "Set context for ${1} (lib: ${CURRENT_LIB} - func: ${CURRENT_LIB_FUNC} - dir: ${CURRENT_LIB_DIR})"
}

### Import DevOps Libs ###
# Usage: import <lib1> <lib2> ... <libN>
function import() {

    # local CURRENT_LIB_FUNC=${FUNCNAME##*.}
    local _libContext='local CURRENT_LIB=${FUNCNAME%.*}; CURRENT_LIB=${CURRENT_LIB#*.};
                    local CURRENT_LIB_DIR=${DEVOPS_LIBS_PATH}/${CURRENT_LIB/./\/}'

    # For each lib
    local _result=0
    while [ "${1}" ]; do
        local _lib="${1}"
        local _libDir=${_lib//./\/}
        local _libPath=${DEVOPS_LIBS_PATH}/${_libDir}
        local _libMain=${_libPath}/${DEVOPS_LIBS_MAIN_FILE}
        local _libTmpPath=${DEVOPS_LIBS_TMP_PATH}/libs/${_libDir}
        local _libTmpMain=${_libTmpPath}/${DEVOPS_LIBS_MAIN_FILE}

        # if lib was already imported
        self _valueInArray ${_lib} "${DEVOPS_LIBS_IMPORTED[@]}"        
        if [[ ${?} -ne 0 ]]; then
            echoInfo "DEVOPS Library '${_lib}' already imported!"
        else
            # Check if it is in online mode to copy/update libs
            if [[ "${DEVOPS_LIBS_MODE}" == "online" || "${DEVOPS_LIBS_MODE}" == "local" ]]; then
                # Include the lib
                self _importLibFiles ${_lib} ${_libPath} ${_libTmpPath} ${_libTmpMain}
                exitOnError "It was not possible to import the library files '${_libTmpPath}'"
            # Check if the lib is available locally
            elif [ ! -f "${_libMain}" ]; then
                # In in auto mode
                if [[ ${DEVOPS_LIBS_MODE} == "auto" && ! -f "${_libTmpMain}" ]]; then
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
                source ${DEVOPS_LIB_LIB_FILE} ${_lib} ${_libPath}
                exitOnError "Error importing '${_libMain}'"

                # Get lib function names
                local _libFuncts=($(bash -c '. '"${DEVOPS_LIB_LIB_FILE} ${_lib} ${_libPath}"' &> /dev/null; typeset -F' | awk '{print $NF}'))

                # Create the functions
                _createLibFunctions ${_lib} "${_libContext}" ${_libFuncts}
            else 
                ((_result+=1)); 
            fi

            # Set as imported
            export DEVOPS_LIBS_IMPORTED+=(${_lib})

            # Show import
            echoInfo "Imported Library '${_lib}' (${_funcCount} functions)"
        fi

        # Go to next arg
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "Some DevOps Libraries were not found!" ${_result}
}