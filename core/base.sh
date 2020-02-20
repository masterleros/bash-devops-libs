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

# @description Validate defined variables
# @arg $@ list variables names to be verified
# @exitcode 0 If all are defined
# @exitcode >0 Amount of variables not defined
function validateVars() {
    local _result=0
    for var in ${@}; do
        if [ -z "${!var}" ]; then
            echoError "Environment varirable '${var}' is not declared!" >&2
            ((_result+=1))
        fi
    done
    return ${_result}
}

### dependencies verification ###
# usage: verifyDeps <dep1> <dep2> ... <depN>
function verifyDeps() {
    local _result=0
    for dep in ${@}; do
        which ${dep} &> /dev/null
        if [[ $? -ne 0 ]]; then
            echoError "Binary dependency '${dep}' not found!" >&2
            ((_result+=1))
        fi
    done
    return ${_result}
}

### Check if a value exists in an array ###
# usage: valueInArray <value> <array>
function valueInArray() {
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

### Get a value from a config file
# usage: configInFile <file> <key>
function configInFile() {
    getArgs "_file _key" "${@}"
    _return=$(cat ${_file} | grep ${_key} | cut -d':' -f2-)
    return $?
}

### Generate the documentation of a lib
# usage: document <lib_dir> <doc_file> [namespace]
function document() {
    
    getArgs "_libDir _docPath &_namespace" "${@}"

    # Check lib folder
    [ -d ${_libDir} ] || exitOnError "Folder '${_libDir}' not found"

    # If namespace add the separator dot
    [ "${_namespace}" ] && _namespace="${_namespace}."

    # Create destination folder is does not exist
    [ -d ${_docPath} ] || mkdir -p $(dirname ${_docPath})

    # Remove old documentation
    [ -f ${_docPath} ] && rm ${_docPath}

    echoInfo "Generating documentation for '${_libDir}'"

    # Process all lib files
    SHDOC_FILES=($(find ${_libDir} -name "*.sh" | sort ))
    for SHDOC_FILE in ${SHDOC_FILES[@]}; do
        # Set the lib subspace
        SHDOC_LIB_SUBSPACE="$(realpath -s --relative-to=${_libDir} $(dirname ${SHDOC_FILE}) | cut -d'.' -f2 | sed "s#/#.#")"
        [ "${SHDOC_LIB_SUBSPACE}" ] && SHDOC_LIB_SUBSPACE="${SHDOC_LIB_SUBSPACE}."

        # Export lib name
        export SHDOC_LIB="${_namespace}${SHDOC_LIB_SUBSPACE}"

        # Append the documentation from the file
        # echoInfo "Docs: processing '${SHDOC_LIB}'"
        # echoInfo "Docs: processing '${SHDOC_FILE}'"
        ${DOLIBS_SHDOC_BIN} < ${SHDOC_FILE} >> ${_docPath}
    done
}