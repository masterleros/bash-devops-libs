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

# @description Validate if the specified variables are defined
# @arg $@ list variables names to be validated
# @exitcode 0 If all are defined
# @exitcode >0 Amount of variables not defined
# @stdout Variables not declared
# @example 
#   validateVars <var1> <var2> ... <varN>
function validateVars() {
    local _result=0
    for var in ${@}; do
        if [ -z "${!var}" ]; then
            echoError "Environment varirable '${var}' is not declared!"
            ((_result+=1))
        fi
    done
    return ${_result}
}

# @description Verify if the specified binaries dependencies are available
# @arg $@ list binaries to be verified
# @exitcode 0 If all are found
# @exitcode >0 Amount of binaries not found
# @stderr Binaries not found
# @example 
#   verifyDeps <bin1> <bin2> ... <binN>
function verifyDeps() {
    local _result=0
    for dep in ${@}; do
        which ${dep} &> /dev/null
        if [[ $? -ne 0 ]]; then
            echoError "Binary dependency '${dep}' not found!"
            ((_result+=1))
        fi
    done
    return ${_result}
}

# @description Check if a value exists in an array
# @arg value value Value to look for
# @arg array array Array to look for the value
# @return Found value position
# @exitcode 0 Value was found
# @exitcode 1 Value not found
# @example 
#   assign valPos=valueInArray <value> <array>
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
    return 1
}

# @description Get a value from a config file in format <key>:<value>
# @arg file path Path to the file
# @arg key Key of the required value
# @return Value of the key
# @exitcode 0 Key found
# @exitcode 1 Key not found
# @example 
#   assign myVar=configInFile <file> <key>
function configInFile() {
    getArgs "_file _key" "${@}"
    _return=$(cat ${_file} | grep ${_key} | cut -d':' -f2-)
    return $?
}

### 
# usage: document <lib_dir> <doc_file> [namespace]

# @description Generate the markdown documentation of a lib
# @arg dir path Directory of the library to be documented
# @arg doc path md file (markdown) to be generated
# @arg namespace string (optional) library's namespace
# @example 
#   document <dir> <file> <namespace>
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
        ${DOLIBS_SHDOC_BIN} < ${SHDOC_FILE} >> ${_docPath}.tmp
    done

    # Rework documentation
    cat ${_docPath}.tmp | grep '\* \[' > ${_docPath}
    cat ${_docPath}.tmp | grep -v '\* \[' >> ${_docPath}
    rm ${_docPath}.tmp 
}