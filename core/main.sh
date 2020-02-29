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
source $(dirname "${BASH_SOURCE[0]}")/base.sh

# @description Use build-in libraries to be used in a script
# @arg $@ list List of libraries names
# @example 
#   use <lib1> <lib2> ... <libN>
function use() {
    
    # List namespaces
    local _libNamespaces=($(echo ${@} | tr ' ' '\n' | cut -d'.' -f1 | uniq))

    # Add all namespaces
    for _libNamespace in ${_libNamespaces[@]}; do        
        # OFFLINE mode
        if [ "${DOLIBS_MODE}" == "offline" ]; then
            self addLocalLib "${_libNamespace}" "${DOLIBS_LIBS_DIR}"
        # Local source
        elif [ "${DOLIBS_LOCAL_SOURCE_DIR}" ]; then
            self addLocalSource "${_libNamespace}" "${DOLIBS_SOURCE_LIBS_DIR}/${_libNamespace}"
        # Git source
        else
            self addGitSource "${_libNamespace}" "${DOLIBS_REPO}" "${DOLIBS_BRANCH}" "libs/${_libNamespace}"
        fi
    done

    # Import libs from embedded sources
    self import "${@}"
}

# @description Import libraries from configured sources to be used in a script
# @arg $@ list List of libraries names
# @example 
#   import <lib1> <lib2> ... <libN>
function import() {

    # For each lib
    while [ "${1}" ]; do
        
        # Current lib
        local _lib="${1}"

        # if lib was already imported
        self valueInArray "${_lib}" "${DOLIBS_IMPORTED[@]}"
        if [[ ${?} -eq 0 ]]; then
            echoInfo "Library '${_lib}' already imported!"

        # If not imported yet
        else
            # Get lib information            
            local _libNamespace=(${_lib//./ })
            local _libPathDir=${_lib/./\/}
            local _libRootDir=${DOLIBS_LIBS_DIR}/${_libNamespace}
            local _libSourceConfig=${_libRootDir}/.source.cfg            
            local _libDir=${DOLIBS_LIBS_DIR}/${_libPathDir}
            local _needInstall=false

            [ -f "${_libSourceConfig}" ] || exitOnError "Source configuration '${_libSourceConfig}' not found for '${_lib}'"

            # Get source type
            assign sourceType=self configInFile "${_libSourceConfig}" TYPE
            [ "${sourceType}" ] || exitOnError "It was not possible to read 'TYPE' source configuration" -1

            # OFFLINE mode
            if [ "${sourceType}" == "OFFLINE" ]; then
                # Update lib dir to the offline folder
                assign _libDir=self configInFile "${_libSourceConfig}" LIB_DIR                                
                _libDir=${_libDir}/${_libPathDir}
            # AUTO mode
            elif [ "${DOLIBS_MODE}" == "auto" ]; then                
                # If the lib is not integral, it needs to update
                if libNotIntegral "${_libDir}"; then
                    echoInfo "It was not possible to check '${_lib}' lib integrity, updating..."
                    local _needInstall=true
                fi
            # ONLINE mode
            elif [ "${DOLIBS_MODE}" == "online" ]; then
                # If the source code was updated, it needs to update
                if libSourceUpdated "${_libSourceDir}" "${_libDir}"; then
                    echoInfo "Source dir changed, updating..."
                    local _needInstall=true
                fi
            fi

            # If needs clone
            if [[ "${_needInstall}" == "true" ]]; then

                # Get the source folder
                assign _libSourceDir=self configInFile "${_libSourceConfig}" SOURCE_DIR
                [ "${_libSourceDir}" ] || exitOnError "It was not possible to read 'SOURCE_DIR' source configuration" -1

                # If is not at the root level, add the sub-namespaces as sub-folders
                if [[ "${_libPathDir}" != "${_libNamespace}" ]]; then
                    _libSourceDir=${_libSourceDir}/${_libPathDir/${_libNamespace}\//}
                fi

                # import files                
                libImportFiles "${_libSourceDir}" "${_libDir}" "${_lib}"

                # Create/update documentation
                self document "${DOLIBS_LIBS_DIR}/${_libNamespace}" "${DOLIBS_DOCUMENTATION_DIR}/${_libNamespace}.md" "${_libNamespace}"
            fi

            # Create the libs and set as imported
            _createLibFunctions "${_lib}" "${_libDir}"
            export DOLIBS_IMPORTED+=("${_lib}")

            # Show import
            echoInfo "Imported Library '${_lib}' (${_funcCount} functions)"
        fi

        # Go to next arg (lib)
        shift
    done
}

# (Private) Function to add a source
# Usage: _addSource <type> <namespace> <data>
function _addSource() {

    getArgs "_sourceType _libNamespace _libRootDir _data" "${@}"

    # Check namespace
    [[ ${_libNamespace} != "do" ]] || exitOnError "Namespace '${_libNamespace}' is reserved"

    local _sourcePath="${_libRootDir}"/.source.cfg

    # Write the file with the data    
    mkdir -p "${_libRootDir}" && 
    echo "TYPE:${_sourceType}" > "${_sourcePath}" &&
    echo "NAMESPACE:${_libNamespace}" >> "${_sourcePath}" &&
    echo "${_data}" >> "${_sourcePath}"

    exitOnError "It was not possible to add the '${_libNamespace}' (${_sourceType}) source"

    echoInfo "Added '${_libNamespace}' lib source (${_sourceType})"
}

# @description Add a git repository source of lib
# @arg namespace string Namespace to import the source's libraries
# @arg repo string Github repository path (i.e: owner/repo)
# @arg branch string Branch name
# @arg dir path Relative path for the lib folder (if libs are in root, use '.')
# @example 
#   addGitSource <namespace> <repo> <branch> <dir>
function addGitSource() {

    getArgs "_libNamespace _gitRepo _gitBranch _libSubDir" "${@}"

    # Create the source data
    local _libRootDir=${DOLIBS_LIBS_DIR}/${_libNamespace}
    local _gitDir=${DOLIBS_TMPDIR}/${_libNamespace}/${_gitBranch}
    local _data="SOURCE_REPO:${_gitRepo}
SOURCE_BRANCH:${_gitBranch}
SOURCE_DIR:${_gitDir}/${_libSubDir}
GIT_DIR:${_gitDir}"

    # OFFLINE mode
    if [ "${DOLIBS_MODE}" == "offline" ]; then
        exitOnError "It is not possible to add a GIT source in '${DOLIBS_MODE}' mode"
    # AUTO mode
    elif [ "${DOLIBS_MODE}" == "auto" ]; then                
        # if source folder does not exist
        if [ ! -d "${_gitDir}" ]; then
            libGitClone "${_gitRepo}" "${_gitBranch}" "${_gitDir}" "${_libRootDir}"
        fi
    # ONLINE mode
    elif [[ "${DOLIBS_MODE}" == "online" ]]; then
        # if the lib is outdated, clone it
        if libGitOutDated "${_libRootDir}" "${_gitDir}"; then
            libGitClone "${_gitRepo}" "${_gitBranch}" "${_gitDir}" "${_libRootDir}"
        fi
    fi

    # Add the source
    self _addSource GIT "${_libNamespace}" "${_libRootDir}" "${_data}"
}

# @description Add a local source of libs (to be copied)
# @arg namespace string Namespace to import the source's libraries
# @arg path path Path to the local directory where the libs are hosted
# @example 
#   addLocalSource <namespace> <path>
function addLocalSource() {

    getArgs "_libNamespace _path" "${@}"

    # Set required vars
    local _libRootDir=${DOLIBS_LIBS_DIR}/${_libNamespace}
    local _data="SOURCE_DIR:${_path}"

    # Add the source
    self _addSource LOCAL "${_libNamespace}" "${_libRootDir}" "${_data}"    
}

# @description Add local libs (to be used from where they are)
# @arg namespace string Namespace to import the source's libraries
# @arg path path Path to the local directory where the libs are hosted
# @example 
#   addLocalSource <namespace> <path>
function addLocalLib() {

    getArgs "_libNamespace _path" "${@}"

    # Set required vars
    local _libRootDir=${DOLIBS_LIBS_DIR}/${_libNamespace}
    local _data="LIB_DIR:${_path}"

    # Add the source
    self _addSource OFFLINE "${_libNamespace}" "${_libRootDir}" "${_data}"   
}
