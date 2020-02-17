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

# Validate OS
if [[ "${BASH}" != *"/bash" ]]; then echo "Current OS is not running on bash interpreter" >&2; exit -1; fi

### DEVOPS LIBS DEFINITIONS ###
DOLIBS_MODE="auto"
DOLIBS_BRANCH="feature/boostrap"
DOLIBS_REPO="masterleros/bash-devops-libs"
### DEVOPS LIBS DEFINITIONS ###
DOLIBS_ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/ >/dev/null 2>&1 && pwd)"/
DOLIBS_DIR="${DOLIBS_ROOTDIR}/dolibs"
### DEVOPS LIBS DEFINITIONS ###

# DevOps libs options
while [ "${1}" != "" ]; do
    case "${1}" in
        # clone mode
        "--online") DOLIBS_MODE='online'; shift 1;;
        "--auto") DOLIBS_MODE='auto'; shift 1;;
        "--offline") DOLIBS_MODE='offline'; shift 1;;
        # dolibs folder    
        "-f") DOLIBS_DIR=${2}; shift 2;;
        # Local source folder (default is git)
        "-l") DOLIBS_LOCAL_SOURCE_DIR="$(cd $(cd $(dirname ${0}) >/dev/null 2>&1 && pwd)/${2} 2>&1 && pwd)"
            if [ ! -d "${DOLIBS_LOCAL_SOURCE_DIR}" ]; then echo "Folder '${2}' does not exist!"; exit -1 ;fi
            shift 2;;
        *) echo "ERROR: Option '${1}' not recognized"; exit -1;;
    esac
done

# Assign the dolibs temp folder
DOLIBS_TMPDIR="${DOLIBS_DIR}/.libtmp"

# If not mode offline
if [[ ${DOLIBS_MODE} != "offline" ]]; then
    # Clone the boostrap if in online mode or it does not exist (auto mode)
    if [[ ${DOLIBS_MODE} != "online" || ! -f ${DOLIBS_DIR}/boostrap.sh ]]; then

        # Create the lib folder
        [ -d ${DOLIBS_DIR}/core ] || mkdir -p ${DOLIBS_DIR}/core
        # If there is a problem, exit
        if [ ${?} -ne 0 ]; then echo "ERROR: It was not possible to create the lib folder, exiting..."; exit -1; fi    

        # Get the boostrap
        if [ "${DOLIBS_LOCAL_SOURCE_DIR}" ]; then
            cp ${DOLIBS_LOCAL_SOURCE_DIR}/core/boostrap.sh ${DOLIBS_DIR}/core/boostrap.sh
        else
            curl -s --fail https://raw.githubusercontent.com/${DOLIBS_REPO}/${DOLIBS_BRANCH}/core/boostrap.sh -o ${DOLIBS_DIR}/core/boostrap.sh
        fi

        # If there is a problem, exit
        if [ ${?} -ne 0 ]; then echo "ERROR: It was not possible to retrieve the boostraper, exiting..."; exit -1; fi
    fi
fi

# Check and enable set e and if is, disable
# set_e_enabled=${-//[^e]/}
# [ ${set_e_enabled} ] || set -e

# Execute the boostrap if is present
if [[ ! -f ${DOLIBS_DIR}/core/boostrap.sh ]]; then
    echo "ERROR: It was not possible to find the boostrap in '${DOLIBS_DIR}/core' (offline mode?)"
    exit -1
fi
. ${DOLIBS_DIR}/core/boostrap.sh

#[ ${set_e_enabled} ] || set +e # Disable set e if was enabled