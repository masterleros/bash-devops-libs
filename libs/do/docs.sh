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

# Define required values
export DOLIBS_DOCUMENTATION_DIR=${DOLIBS_DIR}/docs
export DOLIBS_SHDOC_BIN=${SELF_LIB_DIR}/shdoc.awk

# @description Generate the markdown documentation of a lib
# @arg dir path Directory of the library to be documented
# @arg doc path md file (markdown) to be generated
# @arg namespace string (optional) library's namespace
# @example 
#   document <dir> <file> [namespace]
function document() {
    
    getArgs "_libRootDir _docPath &_namespace" "${@}"

    # Check lib folder
    [ -d "${_libRootDir}" ] || exitOnError "Folder '${_libRootDir}' not found"

    # If namespace add the separator dot
    [ "${_namespace}" ] && _namespace="${_namespace}."

    # Create destination folder is does not exist
    [ -d "${_docPath}" ] || mkdir -p $(dirname "${_docPath}")

    # Remove old documentation
    [ -f "${_docPath}" ] && rm "${_docPath}"

    echoInfo "Generating documentation for '${_libRootDir}'"

    # Process all lib files
    SHDOC_FILES=($(find "${_libRootDir}" -name "*.sh" | sort ))
    for SHDOC_FILE in ${SHDOC_FILES[@]}; do
        # Set the lib subspace
        SHDOC_LIB_SUBSPACE="$(realpath -s --relative-to="${_libRootDir}" $(dirname "${SHDOC_FILE}") | cut -d'.' -f2 | sed "s#/#.#")"
        [ "${SHDOC_LIB_SUBSPACE}" ] && SHDOC_LIB_SUBSPACE="${SHDOC_LIB_SUBSPACE}."

        # Export lib name
        export SHDOC_LIB="${_namespace}${SHDOC_LIB_SUBSPACE}"

        # Append the documentation from the file
        # echoInfo "Docs: processing '${SHDOC_LIB}'"
        # echoInfo "Docs: processing '${SHDOC_FILE}'"
        "${DOLIBS_SHDOC_BIN}" < "${SHDOC_FILE}" >> "${_docPath}.tmp"
    done

    # Rework documentation
    < "${_docPath}.tmp" grep '\* \[' > "${_docPath}"
    < "${_docPath}.tmp" grep -v '\* \[' >> "${_docPath}"
    rm "${_docPath}.tmp"
}
