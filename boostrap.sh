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

DOLIBS_REPO="https://github.com/dodopontocom/bash-devops-libs.git"
DOLIBS_VER="0.2"
DOLIBS_TMPDIR="${DOLIBS_DIR}/.libtmp"
DOLIBS_MAIN_FILE="main.sh"

### Temporary functions ###
function _echo() { echo -e "${2} ${3}" >&"${1}"; }
function echoDebug() { [[ "${DOLIBS_DEBUG}" != *"libs"* ]] || _echo 1 "\e[1m\e[36mDEBUG: \e[0m" "${@}"; }
function echoCore() { [[ "${DOLIBS_DEBUG}" != *"core"* ]] || _echo 1 "\e[1m\e[35mDEBUG: \e[0m" "${@}"; }
function echoInfo()  { _echo 1 "\e[1m\e[32mINFO:  \e[0m" "${@}"; }
function echoWarn()  { _echo 1 "\e[1m\e[33mWARN:  \e[0m" "${@}"; }
function echoError() { _echo 2 "\e[1m\e[31mERROR: \e[0m" "${@}"; }
function exitOnError() {
    if [ "${2:-$?}" != 0 ]; then
        echoError "${1}"
        echoError "Exiting (${_errorCode})..."
        exit "${_errorCode}"
    fi
}
### Temporary functions ###

### Function to clone the lib code ###
# usage: _dolibGitClone <GIT_REPO> <GIT_BRANCH> <GIT_DIR> <LIB_ROOT_DIR>
function _dolibGitClone() {

    local GIT_REPO=${1}
    local GIT_BRANCH=${2}
    local GIT_DIR=${3}
    local LIB_ROOT_DIR=${4}
    local SOURCE_STATE="${LIB_ROOT_DIR}/.source.state"

    # Check if git is present
    which git &> /dev/null || exitOnError "Git command not found"            

    # Get the code        
    if [ ! -d "${GIT_DIR}" ]; then            
        echoCore "Cloning Libs code from '${GIT_REPO}'..."
        git clone -q -b "${GIT_BRANCH}" --single-branch "${GIT_REPO}" "${GIT_DIR}"
    else
        echoCore "Updating Libs code from '${GIT_REPO}'..."
        git -C "${GIT_DIR}" pull -q
    fi
    exitOnError "It was not possible to clone the GIT code"

    # Update retrieved lib status
    mkdir -p "${LIB_ROOT_DIR}"
    cat << EOF > "${SOURCE_STATE}"
GIT_DIR:${GIT_DIR}
GIT_BRANCH:${GIT_BRANCH}
GIT_HASH:$(cd "${GIT_DIR}"; git rev-parse HEAD)
GIT_USER:$(git config user.name)
GIT_EMAIL:$(git config user.email)
UPDATED:$(date)
HOSTNAME:$(hostname)
EOF
   
}

### Function to indicate if the lib code is outdated ###
# usage: _dolibGitOutDated <LIB_ROOT_DIR>
function _dolibGitOutDated() {

    local LIB_ROOT_DIR=${1}
    local GIT_DIR=${2}
    local SOURCE_STATE="${LIB_ROOT_DIR}/.source.state"

    # If state dos not exist
    [ -f "${SOURCE_STATE}" ] || return 0

    # If source dos not exist
    [ -d "${GIT_DIR}" ] || return 0

    # Get local status
    local GIT_BRANCH=$(< "${SOURCE_STATE}" grep GIT_BRANCH | cut -d':' -f2-)
    local GIT_HASH=$(< "${SOURCE_STATE}" grep GIT_HASH | cut -d':' -f2-)

    # Get git remote hash
    local GIT_ORIGIN_HASH=$(cd "${GIT_DIR}" && git fetch -q && git rev-parse origin/"${GIT_BRANCH}")

    # Return result
    [ "${GIT_ORIGIN_HASH}" != "${GIT_HASH}" ]
}

### Function to indicate if the lib code branch has changed ###
# usage: _dolibGitWrongBranch <LIB_ROOT_DIR> <GIT_BRANCH>
function _dolibGitWrongBranch() {

    local LIB_ROOT_DIR=${1}
    local GIT_BRANCH=${2}
    local SOURCE_STATE="${LIB_ROOT_DIR}/.source.state"

    # If state dos not exist
    [ -f "${SOURCE_STATE}" ] || return 0

    # Return if current state branch is different than required
    [ "${GIT_BRANCH}" != $(< "${SOURCE_STATE}" grep GIT_BRANCH | cut -d':' -f2-) ]
}

### Function to indicate if the local source (or cache) is different than the lib ###
# usage: _dolibSourceUpdated <SOURCE_DIR> <LIB_DIR>
function _dolibSourceUpdated() {
    local LIB_SOURCE_DIR=${1}
    local LIB_DIR=${2}

    # Validate source and lib folder differences
    [ "$(cd "${LIB_SOURCE_DIR}"; find -maxdepth 1 -type f \( ! -iname ".source.cfg" ! -iname ".source.state" ! -iname ".lib.shasum" \) -exec diff {} "${LIB_DIR}"/{} \; 2>&1)" ]
}

### Import Lib files ###
# Usage: _dolibImportFiles <SOURCE_DIR> <LIB_DIR>
function _dolibImportFiles() {
    
    local LIB_SOURCE_DIR=${1}
    local LIB_DIR=${2}
    local LIB=${3}
    local LIB_SHASUM_PATH="${LIB_DIR}/.lib.shasum"

    echoCore "Installing '${LIB}' code..."

    # Check if the lib entrypoint exists
    [ -f "${LIB_SOURCE_DIR}/${DOLIBS_MAIN_FILE}" ] || exitOnError "Library source '${LIB_SOURCE_DIR}' not found! (does it need add source?)"

    # Create lib dir
    mkdir -p "${LIB_DIR}"
    exitOnError "Could not create the '${LIB_DIR}' folder"

    # Copy the files (ignore the auto generated)
    find "${LIB_SOURCE_DIR}" -maxdepth 1 -type f \( ! -iname ".source.cfg" ! -iname ".source.state" ! -iname ".lib.shasum" \) -exec cp {} "${LIB_DIR}" \;
    exitOnError "Could not import the '${LIB_SOURCE_DIR}' library files"

    # Add the checksum file
    shasum=$(find "${LIB_DIR}" -maxdepth 1 -type f ! -path "${LIB_SHASUM_PATH}" -exec sha1sum {} \; | sha1sum | cut -d' ' -f1)
    echo "SHASUM:${shasum}" > "${LIB_SHASUM_PATH}"
}

### Check if the libs files are valid ###
# Usage: _dolibNotIntegral <LIB_DIR>
function _dolibNotIntegral() {
    
    local LIB_DIR=${1}
    local LIB_SHASUM_PATH="${LIB_DIR}/.lib.shasum"

    # If sha does not exist exist
    [ -f "${LIB_SHASUM_PATH}" ] || return 0
  
    # Get current sha
    local LIB_SHASUM=$(< "${LIB_SHASUM_PATH}" grep SHASUM | cut -d':' -f2-)

    # Calculate sha     
    local CALCULATED_SHASUM=$(find "${LIB_DIR}" -maxdepth 1 -type f ! -path "${LIB_SHASUM_PATH}" -exec sha1sum {} \; | sha1sum | cut -d' ' -f1)

    # Return result
    [ "${LIB_SHASUM}" != "${CALCULATED_SHASUM}" ]    
}

### Update the a lib code if it is required ###
# Usage: _dolibUpdate <MODE> <SOURCE_DIR> <TARGET_DIR> [GIT_DIR]
# obs: if not GIT_DIR is provided, it's threated as local source
# return 0 if updated, 1 if not present, 2 if auto mode but branch changed, 3 if git updated, 4 if source updated
function _dolibUpdate() {

    local LIB=${1}
    local LIB_SOURCE_DIR=${2}
    local LIB_ROOT_DIR=${3}
    local LIB_SUB_DIR=${4}
    local GIT_DIR=${5}
    local GIT_REPO=${6}
    local GIT_BRANCH=${7}
    local LIB_DIR=${LIB_ROOT_DIR}; [ "${LIB_SUB_DIR}" ] && LIB_DIR="${LIB_ROOT_DIR}/${LIB_SUB_DIR}"
    local _result=0

    # AUTO mode
    if [ "${DOLIBS_MODE}" == 'auto' ]; then
        # If the lib is not integral, needs to update
        if _dolibNotIntegral "${LIB_DIR}"; then
            echoCore "It was not possible to check '${LIB}' lib integrity, trying to get its code..."
            _result=1
        elif [ "${GIT_DIR}" ] && _dolibGitWrongBranch "${LIB_ROOT_DIR}" "${GIT_BRANCH}"; then
            echoCore "Source branch has changed, trying to get its code..."
            _result=2
        fi
    # ONLINE mode
    elif [ "${DOLIBS_MODE}" == 'online' ]; then
        # If the lib is outdated, clone it
        if [ "${GIT_DIR}" ] && _dolibGitOutDated "${LIB_ROOT_DIR}" "${GIT_DIR}" ]; then
            echoCore "GIT Source has changed for '${LIB}', trying to get its code..."
            _result=3
        # If the lib is outdated, copy it
        elif _dolibSourceUpdated "${LIB_SOURCE_DIR}" "${LIB_DIR}"; then
            echoCore "Local source has changed for '${LIB}', trying to get its code..."
            _result=4
        fi
    fi

    # if needs to update
    if [ "${_result}" != 0 ]; then
        [ "${GIT_DIR}" ] && _dolibGitClone "${GIT_REPO}" "${GIT_BRANCH}" "${GIT_DIR}" "${LIB_ROOT_DIR}"
        _dolibImportFiles "${LIB_SOURCE_DIR}" "${LIB_DIR}" "${LIB}"
    fi

    return ${_result}
}

# Show operation mode
echo
echoInfo "Initializing \e[1mdolibs\e[0m (v${DOLIBS_VER})"
if [ "${DOLIBS_MODE}" != 'offline' ]; then 
    if [ "${DOLIBS_LOCAL_SOURCE_DIR}" ]; then 
        echoInfo "(${DOLIBS_MODE}) from local source - '${DOLIBS_LOCAL_SOURCE_DIR}'"
    else
        echoInfo "(${DOLIBS_MODE}) from GIT source - branch '${DOLIBS_BRANCH}'"
    fi
fi

# If Core library was not yet loaded
if [ ! "${DOLIBS_LOADED}" ]; then

    # core folder
    DOLIBS_CORE_DIR=${DOLIBS_DIR}/core    

    # If not working offline
    if [ "${DOLIBS_MODE}" != 'offline' ]; then

        # Local mode
        if [ "${DOLIBS_LOCAL_SOURCE_DIR}" ]; then 
            DOLIBS_SOURCE_DIR="${DOLIBS_LOCAL_SOURCE_DIR}"
        # GIT mode
        else 
            DOLIBS_SOURCE_DIR="${DOLIBS_TMPDIR}/core/${DOLIBS_BRANCH}"; 
            DOLIBS_GIT_DIR="${DOLIBS_SOURCE_DIR}"
        fi

        # dolibs core functions dirs
        DOLIBS_SOURCE_CORE_DIR=${DOLIBS_SOURCE_DIR}/core        

        # Update lib if required
        _dolibUpdate "core" "${DOLIBS_SOURCE_CORE_DIR}" "${DOLIBS_CORE_DIR}" "" "${DOLIBS_GIT_DIR}" "${DOLIBS_REPO}" "${DOLIBS_BRANCH}"

        # If lib was updated, update others required
        if [ ${?} != 0 ]; then

            # Copy the gitignore
            cp "${DOLIBS_SOURCE_DIR}"/.gitignore "${DOLIBS_DIR}"

            # Copy license
            cp "${DOLIBS_SOURCE_DIR}"/LICENSE "${DOLIBS_DIR}"/LICENSE
            cp "${DOLIBS_SOURCE_DIR}"/NOTICE "${DOLIBS_DIR}"/NOTICE

            # Copy the Libs help
            cp "${DOLIBS_SOURCE_DIR}"/README.md "${DOLIBS_DIR}"/README.md
            cp "${DOLIBS_SOURCE_DIR}"/libs/README.md "${DOLIBS_DIR}"/DEVELOPMENT.md
        fi
    fi

    ### Include Libs ###
    if [ -f "${DOLIBS_CORE_DIR}/${DOLIBS_MAIN_FILE}" ]; then        
        . "${DOLIBS_CORE_DIR}/${DOLIBS_MAIN_FILE}"
        exitOnError "Could not import DevOps Libs"
    else
        exitOnError "Could not find DevOps Libs (offline mode?)" 1
    fi
fi

# Check required binaries
# git
# diff
# tr
# shasum
