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

### Import DevOps Lib files ###
# Usage: _importLibFiles <lib>
function _importLibFiles() {
    
    getArgs "_lib _libPath _libTmpPath _libTmpMain" "${@}"

    # Check if the lib is available from download
    if [ -f ${_libTmpMain} ]; then
        # Create lib dir and copy
        #mkdir -p ${_libPath} && cp -r ${_libTmpPath}/* ${_libPath}
        mkdir -p ${_libPath} && cp ${_libTmpPath}/*.* ${_libPath}
        exitOnError "Could not copy the '${_lib}' library files"
        return 0        
    fi
    
    echoError "DEVOPS Library '${_lib}' not found! (was it downloaded already? / needs do.addCustomGitSource?)"
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

### Get a value from a config file
# usage: _configInFile <file> <key>
function _configInFile() {
    getArgs "_file _key" "${@}"
    _return=$(cat ${_file} | grep ${_key} | cut -d':' -f2-)
    return $?
}

### Import DevOps Libs ###
# Usage: import <lib1> <lib2> ... <libN>
function import() {

    # For each lib
    while [ "${1}" ]; do
        
        # Current lib
        local _lib="${1}"

        # if lib was already imported
        self _valueInArray ${_lib} "${DOLIBS_IMPORTED[@]}"
        if [[ ${?} -eq 0 ]]; then
            echoInfo "DEVOPS Library '${_lib}' already imported!"

        # If not imported yet
        else
            local _libNamespace=(${_lib//./ })
            local _libDir=${_lib/./\/}
            local _libPath=${DOLIBS_DIR}/${_libDir}

            # If it is a local custom lib
            if [[ ${_libNamespace} == "local" ]]; then
                # Get local config position
                [ "${DOLIBS_LOCAL_REPO}" ]
                exitOnError "The 'local' library was not configured (needs do.addLocalSource?)"

                local _libDir=${_libDir/${_libNamespace}\//}
                local _libPath=${DOLIBS_LOCAL_REPO}/${_libDir}
            
            # If offline mode use current folders, else check remote
            elif [[ "${DOLIBS_MODE}" != "offline" ]]; then

                # if it's an external sourced lib
                local _sourceConfig=${DOLIBS_DIR}/${_libNamespace}/source.cfg
                if [ -f ${_sourceConfig} ]; then
                    # Get remote config
                    assign _gitRepo=self _configInFile ${_sourceConfig} DOLIBS_CUSTOM_REPO
                    assign _gitBranch=self _configInFile ${_sourceConfig} DOLIBS_CUSTOM_BRANCH
                    assign _gitDir=self _configInFile ${_sourceConfig} DOLIBS_CUSTOM_TMP_DIR
                    local _libRootParentDir=${DOLIBS_DIR}/${_libNamespace}
                    local _libDir=${_libDir/${_libNamespace}\//}
                    local _libPath=${DOLIBS_DIR}/${_libNamespace}/${_libDir}
                # Else is an internal lib
                else
                    local _gitRepo=${DOLIBS_REPO}
                    local _gitBranch=${DOLIBS_BRANCH}
                    local _gitDir=${DOLIBS_TMP_DIR}
                    local _libRootParentDir=${DOLIBS_DIR}                    
                fi
                
                # Cloned Lib location
                local _libMain=${_libPath}/${DOLIBS_MAIN_FILE}
                local _gitStatus=${_libRootParentDir}/dolibs.status
                local _gitTmpStatus=${_gitDir}/dolibs.status
                local _libTmpPath=${_gitDir}/libs/${_libDir}
                local _libTmpMain=${_libTmpPath}/${DOLIBS_MAIN_FILE}

                # LOCAL
                if [[ "${DOLIBS_MODE}" == "local" ]]; then
                    # Import the lib
                    self _importLibFiles ${_lib} ${_libPath} ${_libTmpPath} ${_libTmpMain}
                    exitOnError "It was not possible to import the library files '${_libTmpPath}'"
                
                # ONLINE (allways clone)
                elif [[ "${DOLIBS_MODE}" == "online" ]]; then

                    # Try to clone the lib code
                    devOpsLibsClone ${_gitRepo} ${_gitBranch} ${_gitDir} ${_gitTmpStatus}
                    exitOnError "It was not possible to clone the library code"
                                    
                    # Import the lib
                    self _importLibFiles ${_lib} ${_libPath} ${_libTmpPath} ${_libTmpMain}
                    exitOnError "It was not possible to import the library files '${_libTmpPath}'"

                    # Update git status
                    cp ${_gitTmpStatus} ${_gitStatus}
                    exitOnError "It was not possible to update git status file '${_gitStatus}'"

                # AUTO (clone when changes are detected)
                elif [[ "${DOLIBS_MODE}" == "auto" ]]; then

                    # Get git statuses
                    local _currentHash=$([ ! -f "${_gitTmpStatus}" ] || cd ${_gitDir} && git rev-parse HEAD)
                    local _remoteHash=$([ ! -f "${_gitTmpStatus}" ] || cd ${_gitDir} && git rev-parse origin/${_gitBranch})

                    # Code not cloned / Changed detected
                    if [[ ! -f "${_gitTmpStatus}" || "${_currentHash}" != "${_remoteHash}" ]]; then

                        echoInfo "AUTO MODE - '${_lib}' has changed, cloning code..."

                        # Try to clone the lib code
                        devOpsLibsClone ${_gitRepo} ${_gitBranch} ${_gitDir} ${_gitTmpStatus}
                        exitOnError "It was not possible to clone the library code"

                        # Import the lib                        
                        self _importLibFiles ${_lib} ${_libPath} ${_libTmpPath} ${_libTmpMain}
                        exitOnError "It was not possible to import the library files '${_libTmpPath}'"                        
                    fi

                    # If not found locally or branch has changed, import
                    if [[ ! -f "${_libMain}" || ! -f "${_gitStatus}" || "$(cat ${_gitTmpStatus})" != "$(cat ${_gitStatus})" ]]; then

                        self _importLibFiles ${_lib} ${_libPath} ${_libTmpPath} ${_libTmpMain}
                        exitOnError "It was not possible to import the library files '${_libTmpPath}'"

                        # Update git status
                        cp ${_gitTmpStatus} ${_gitStatus}
                        exitOnError "It was not possible to update git status file '${_gitStatus}'"                        
                    fi
                fi
            fi

            # Create the libs and set as imported
            _createLibFunctions ${_libPath} ${_lib}
            export DOLIBS_IMPORTED+=(${_lib})

            # Show import
            echoInfo "Imported Library '${_lib}' (${_funcCount} functions)"
        fi

        # Go to next arg (lib)
        shift
    done
}

# Function to add a custom lib source
# Usage: _addCustomSource <type> <space> <git_url> <optional_branch>
function _addCustomSource() {

    getArgs "_namespace _url &_branch" "${@}"

    # Set default branch case not specified
    if [ ! "${_branch}" ]; then _branch="master"; fi
    
    # Write the file with the data
    local _libPath=${DOLIBS_DIR}/${_namespace}
    mkdir -p  ${_libPath}
    cat << EOF > ${_libPath}/source.cfg
DOLIBS_CUSTOM_NAMESPACE:${_namespace}
DOLIBS_CUSTOM_REPO:${_url}
DOLIBS_CUSTOM_BRANCH:${_branch}
DOLIBS_CUSTOM_TMP_DIR:${DOLIBS_DIR}/.libtmp/custom/${_namespace}/${_branch}
EOF
}

# Function to add a custom lib git repository source
# Usage: addCustomGitSource <namespace> <git_url> <optional_branch>
function addCustomGitSource() {

    getArgs "_namespace _url &_branch" "${@}"

    # Check if in local mode
    [[ ${DOLIBS_MODE} != 'local' && ${DOLIBS_MODE} != 'offline' ]] || exitOnError "Custom remote sources are not supported in '${DOLIBS_MODE}' mode!"
    [[ ${_namespace} != "local" ]] || exitOnError "Namespace 'local' is reserved for local sources!"

    self _addCustomSource ${_namespace} ${_url} ${_branch}    
    echoInfo "Added custom GIT lib '${_namespace}'"
}

# Function to add a custom lib git repository source
# Usage: addLocalSource <path>
function addLocalSource() {

    getArgs "_path" "${@}"

    # Get the real path
    _path="$(cd ${_path}/ >/dev/null 2>&1 && pwd)"

    # Check if in local mode
    [[ -d "${_path}" ]] || exitOnError "Library path '${_path}' not found!"

    # Add local source
    export DOLIBS_LOCAL_REPO=${_path}
    echoInfo "Added local source '${_path}'"
}

# Function to look for and import automatically all dolibs usages in the files
# Usage: recursiveImport <path>
function recursiveImport() {

    getArgs "_path" "${@}"

    # Look for custom sources
    local _gitSources=$(find ${_path} -name "*.sh" -type f -print -exec cat {} \; \
                       | egrep -o '^([[:space:]])*do.addCustomGitSource .*' \
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