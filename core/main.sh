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
source $(dirname ${BASH_SOURCE[0]})/base.sh

### Import Libs ###
# Usage: import <lib1> <lib2> ... <libN>
function import() {

    # For each lib
    while [ "${1}" ]; do
        
        # Current lib
        local _lib="${1}"

        # if lib was already imported
        self valueInArray ${_lib} "${DOLIBS_IMPORTED[@]}"
        if [[ ${?} -eq 0 ]]; then
            echoInfo "Library '${_lib}' already imported!"

        # If not imported yet
        else
            # Get lib information            
            local _libNamespace=(${_lib//./ })
            local _libPathDir=${_lib/./\/}
            local _libRootDir=${DOLIBS_LIBS_DIR}/${_libNamespace}
            local _libSourceConfig=${_libRootDir}/.source.cfg            

            [ -f "${_libSourceConfig}" ] || exitOnError "Source configuration '${_libSourceConfig}' not found for '${_lib}'"

            # Get source type
            assign sourceType=self configInFile ${_libSourceConfig} TYPE

            # If it is in offline mode
            if [[ "${sourceType}" == "OFFLINE" ]]; then
                assign _libDir=self configInFile ${_libSourceConfig} LIB_DIR
            else
                # Local dir will be on dolibs
                local _libDir=${DOLIBS_LIBS_DIR}

                # If is a local source
                if [[ "${sourceType}" == "LOCAL" ]]; then
                    assign _libSourceDir=self configInFile ${_libSourceConfig} SOURCE_DIR

                # If is a git source
                elif [[ "${sourceType}" == "GIT" ]]; then                    
                    assign _gitRepo=self configInFile ${_libSourceConfig} SOURCE_REPO
                    assign _gitBranch=self configInFile ${_libSourceConfig} SOURCE_BRANCH
                    assign _libSubDir=self configInFile ${_libSourceConfig} SOURCE_LIB_SUBDIR
                    local _gitDir="${DOLIBS_TMPDIR}/${_libNamespace}/${_gitBranch}"
                    local _libSourceDir=${_gitDir}/${_libSubDir}

                    # if the lib is outdated, clone it
                    if devOpsLibsOutDated ${_libRootDir}; then
                        devOpsLibsClone ${_gitRepo} ${_gitBranch} ${_gitDir} ${_libRootDir}
                    fi      
                fi

                # If is not at the root level, add the sub-namespaces as sub-folders
                if [[ "${_libPathDir}" != "${_libNamespace}" ]]; then
                    _libSourceDir=${_libSourceDir}/${_libPathDir/${_libNamespace}\//}
                fi

                # import files
                importLibFiles ${_libSourceDir} ${_libDir}/${_libPathDir}
            fi

            # Create the libs and set as imported
            _createLibFunctions ${_lib} ${_libDir}/${_libPathDir}
            export DOLIBS_IMPORTED+=(${_lib})

            # Show import
            echoInfo "Imported Library '${_lib}' (${_funcCount} functions)"
        fi

        # Go to next arg (lib)
        shift
    done
}

# Function to add a lib git repository source
# Usage: addGitSource <namespace> <git_url> <git_branch> <lib_subdir> 
function addGitSource() {

    getArgs "_namespace _gitUrl _branch _libSubDir" "${@}"

    # Check namespace
    [[ ${_namespace} != "do" ]] || exitOnError "Namespace '${_namespace}' is reserved"
    
    # Write the file with the data
    local _libPath=${DOLIBS_LIBS_DIR}/${_namespace}
    mkdir -p  ${_libPath}
    cat << EOF > ${_libPath}/.source.cfg
TYPE:GIT
NAMESPACE:${_namespace}
SOURCE_REPO:${_gitUrl}
SOURCE_BRANCH:${_branch}
SOURCE_LIB_SUBDIR:${_libSubDir}
EOF

    echoInfo "Added GIT lib '${_namespace}'"
}

# Function to add a local lib source
# Usage: addLocalSource <namespace> <path>
function addLocalSource() {

    getArgs "_namespace _path" "${@}"
    
    # Check namespace
    [[ ${_namespace} != "do" ]] || exitOnError "Namespace '${_namespace}' is reserved"

    # Write the file with the data
    local _libPath=${DOLIBS_LIBS_DIR}/${_namespace}
    mkdir -p  ${_libPath}
    cat << EOF > ${_libPath}/.source.cfg
TYPE:LOCAL
NAMESPACE:${_namespace}
SOURCE_DIR:${_path}
EOF

    echoInfo "Added Local Sourced lib '${_namespace}'"
}

# Function to add a local lib source
# Usage: addLocalLib <namespace> <path>
function addLocalLib() {

    getArgs "_namespace _path" "${@}"

    # Check namespace
    [[ ${_namespace} != "do" ]] || exitOnError "Namespace '${_namespace}' is reserved"

    # Write the file with the data
    local _libPath=${DOLIBS_LIBS_DIR}/${_namespace}
    mkdir -p  ${_libPath}
    cat << EOF > ${_libPath}/.source.cfg
TYPE:OFFLINE
NAMESPACE:${_namespace}
LIB_DIR:${_path}
EOF

    echoInfo "Added Local lib '${_namespace}'"
}

### Import embedded Libs ###
# Usage: use <lib1> <lib2> ... <libN>
function use() {
    
    # List namespaces
    local _namespaces=($(echo ${@} | tr ' ' '\n' | cut -d'.' -f1 | uniq))

    # Add all namespaces
    for _namespace in ${_namespaces[@]}; do        
        # If not in mode offline
        if [[ ${DOLIBS_MODE} == offline ]]; then
            self addLocalLib "${_namespace}" "${DOLIBS_LIBS_DIR}"
        else
            self addLocalSource "${_namespace}" "${DOLIBS_SOURCE_LIBS_DIR}/${_namespace}"
        fi
    done

    # Import libs from embedded sources
    self import "${@}"
}

# Function to look for and import automatically all dolibs usages in the files
# Usage: recursiveImport <path>
function recursiveImport() {

    getArgs "_path" "${@}"

    # Look for custom sources
    local _gitSources=$(find ${_path} -name "*.sh" -type f -print -exec cat {} \; \
                       | egrep -o '^([[:space:]])*do.addGitSource .*' \
                       | sort -u)

    # Configure each git source found
    for _gitSource in "${_gitSources[@]}"; do        
        eval "${_gitSource}"
    done

    # Look into files for imports
    local _libs=$(find ${_path} -name "*.sh" -type f -print -exec cat {} \; \
                | egrep -o 'do.import([[:space:]]{1,}([[:alnum:]]|\.){1,}){1,}' \
                | egrep -v 'local.' \
                | cut -d' ' -f2- \
                | tr ' ' '\n' \
                | sort -u \
                | paste -s -d' ')

    exitOnError "It was not possible to get the required libraries"

    # Import each library
    echoInfo "Found libraries: ${_libs}"
    do.import ${_libs}
}
