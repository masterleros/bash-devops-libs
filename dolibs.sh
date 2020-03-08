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

# @file dolibs.sh
# @brief This is de main entrypoint for the lib and needs to be copied whithin your source files, then it needs to be included

# Validate OS
if [ ! "${BASH}" ]; then echo "Current OS is not running on bash interpreter" >&2; exit -1; fi

### DEVOPS LIBS DEFINITIONS ###
DOLIBS_MODE="auto"
DOLIBS_BRANCH="develop"
### DEVOPS LIBS DEFINITIONS ###
DOLIBS_ROOTDIR=$(cd $(dirname "${BASH_SOURCE[0]}")/ >/dev/null 2>&1 && pwd)
DOLIBS_DIR=${DOLIBS_ROOTDIR}/dolibs
DOLIBS_GIT_BOSTRAP="https://raw.githubusercontent.com/masterleros/bash-devops-libs/${DOLIBS_BRANCH}/boostrap.sh"
### DEVOPS LIBS DEFINITIONS ###

# DevOps libs options
while [ "${1}" != "" ]; do
    case "${1}" in
        # clone mode
        "--online") DOLIBS_MODE="online"; shift 1;;
        "--auto") DOLIBS_MODE="auto"; shift 1;;
        "--debug") DOLIBS_DEBUG="${DOLIBS_DEBUG} libs"; shift 1;;
        "--debug-core") DOLIBS_DEBUG="${DOLIBS_DEBUG} core"; shift 1;;
        "--offline")
            # if online mode, use same source as included            
            DOLIBS_DIR=${DOLIBS_ROOTDIR}
            DOLIBS_MODE="offline"; shift 1;;
        # dolibs folder    
        "-f") DOLIBS_DIR=${2}; shift 2;;
        # Local source folder (default is git)
        "-l") DOLIBS_LOCAL_SOURCE_DIR=$(cd $(cd $(dirname "${0}") >/dev/null 2>&1 && pwd)/"${2}" 2>&1 && pwd)
            if [ ! -d "${DOLIBS_LOCAL_SOURCE_DIR}" ]; then echo "Folder '${2}' does not exist!"; exit -1 ;fi
            shift 2;;
        *) echo "ERROR: Option '${1}' not recognized"; exit -1;;
    esac
done

# If not mode offline
DOLIBS_BOSTRAP="${DOLIBS_DIR}/boostrap.sh"
if [ "${DOLIBS_MODE}" != "offline" ]; then
    # Clone the boostrap if in online mode or it does not exist (auto mode)    
    if [ "${DOLIBS_MODE}" == "online" ] || [ ! -f "${DOLIBS_BOSTRAP}" ]; then

        # Create the lib folder
        [ -d "${DOLIBS_DIR}" ] || mkdir -p "${DOLIBS_DIR}"
        # If there is a problem, exit
        if [ ${?} -ne 0 ]; then echo "ERROR: It was not possible to create the lib folder, exiting..."; exit -1; fi    

        # Get the boostrap
        if [ "${DOLIBS_LOCAL_SOURCE_DIR}" ]; then
            cp "${DOLIBS_LOCAL_SOURCE_DIR}/boostrap.sh" "${DOLIBS_BOSTRAP}"
        else
            DOLIBS_BOSTRAP="${DOLIBS_DIR}/boostrap-${DOLIBS_BRANCH//\//-}.sh"
            curl -s -H 'Cache-Control: no-cache' --fail "${DOLIBS_GIT_BOSTRAP}" -o "${DOLIBS_BOSTRAP}"            
        fi

        # If there is a problem, exit
        if [ ${?} -ne 0 ]; then echo "ERROR: It was not possible to retrieve the boostraper (check source), exiting..."; exit -1; fi
    fi
fi

# Execute the boostrap if is present
if [ ! -f "${DOLIBS_BOSTRAP}" ]; then
    echo "ERROR: It was not possible to find the boostrap at '${DOLIBS_BOSTRAP}' (offline mode?)"
    exit -1
fi

# Execute the bootstrap
. "${DOLIBS_BOSTRAP}"
