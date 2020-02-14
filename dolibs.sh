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
DOLIBS_DEFAULT_MODE="auto"
DOLIBS_BRANCH="feature/boostrap"
DOLIBS_REPO="masterleros/bash-devops-libs"
### DEVOPS LIBS DEFINITIONS ###
export DOLIBS_MODE="${DOLIBS_DEFAULT_MODE}"
export DOLIBS_ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/ >/dev/null 2>&1 && pwd)"
### DEVOPS LIBS DEFINITIONS ###

# DevOps libs options
while [ "${1}" != "" ]; do
    case "${1}" in
        # clone mode
        "-m") export DOLIBS_MODE=${2}; shift 2;;    
        # dolibs root folder    
        "-f") export DOLIBS_ROOTDIR=${2}; shift 2;;
        # Local mode folder
        "-l") export DOLIBS_LOCAL_MODE_DIR="$(cd $(cd $(dirname ${0}) >/dev/null 2>&1 && pwd)/${2} 2>&1 && pwd)"
            if [ ! -d "${DOLIBS_LOCAL_MODE_DIR}" ]; then echo "Folder '${2}' does not exist!"; exit -1 ;fi
            shift 2;;
        *) echo "ERROR: Option '${1}' not recognized"; exit -1;;
    esac
done

# Assign the dolibs root folder
export DOLIBS_DIR="${DOLIBS_ROOTDIR}/dolibs"

# Clone the lib code if required
if [[ ! -f ${DOLIBS_DIR}/boostrap.sh || ${DOLIBS_MODE} == "online" ]]; then    
    [ -d ${DOLIBS_DIR} ] || mkdir -p ${DOLIBS_DIR}
    curl -s --fail https://raw.githubusercontent.com/${DOLIBS_REPO}/${DOLIBS_BRANCH}/libs/boostrap.sh -o ${DOLIBS_DIR}/boostrap.sh
    if [ ${?} -ne 0 ]; then
        echo "ERROR: It was not possible to download the boostraper script, exiting..."
        exit -1
    fi
fi

# Execute the boostrap
. ${DOLIBS_DIR}/boostrap.sh
