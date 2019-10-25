#!/bin/bash
#
# This script provides the common definitions and funcions to execute
# to help scripts contextualize the executions
#
export ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd)"

### DEVOPS LIBS BRANCH ###
DEVOPS_LIBS_BRANCH="feature/lib-updates"
DEVOPS_LIBS_SERVER="git.gft.com"
DEVOPS_LIBS_REPO="devops-br/gitlab-gft-libs.git"
### DEVOPS LIBS DEFINITIONS ###

###############################
export DEVOPS_LIBS_MODE=${1}
export DEVOPS_LIBS_DIR="${ROOTDIR}/scripts/devops-libs"    
export DEVOPS_LIBS_TMP_DIR="${DEVOPS_LIBS_DIR}/.libtmp/${DEVOPS_LIBS_BRANCH}"
###############################

# Validate OS
if [[ "${OSTYPE}" != "linux-gnu" ]]; then echo "OS '${OSTYPE}' is not supported" >&2; exit -1; fi

# Check if the execution in on DevOps
if [ "${CI}" ]; then echo "---> Running on DevOps CI/CD <---"; fi

############## VALIDATE OPERATION MODE #################
if [ ! ${DEVOPS_LIBS_MODE} ]; then export DEVOPS_LIBS_MODE='auto'; fi # Set default mode case not provided
if [[ ${DEVOPS_LIBS_MODE} == 'auto' && ! -f ${DEVOPS_LIBS_DIR}/base.sh ]]; then 
    echo "DevOps Libs not found! forcing online mode..."
    export DEVOPS_LIBS_MODE='online'; 
fi
#########################################################

# Function to clone the lib
function devOpsLibsClone() {

    # Check if git is present
    if [ $(which git &> /dev/null || echo $?) ]; then echo 'ERROR: git command is required!' >&2; exit -1; fi

    ### Clone / update the libraries ###
    set_e_enabled=${-//[^e]/}
    [ ${set_e_enabled} ] || set -e # Enable set e

    echo "Retrieving DevOps Libs code...."

    # Get the code
    if [ ! -d ${DEVOPS_LIBS_TMP_DIR} ]; then
        if [ ${CI_JOB_TOKEN} ]; then
            git clone -b ${DEVOPS_LIBS_BRANCH} --single-branch https://gitlab-ci-token:${CI_JOB_TOKEN}@${DEVOPS_LIBS_SERVER}/${DEVOPS_LIBS_REPO} ${DEVOPS_LIBS_TMP_DIR}
        else
            git clone -b ${DEVOPS_LIBS_BRANCH} --single-branch git@${DEVOPS_LIBS_SERVER}:${DEVOPS_LIBS_REPO} ${DEVOPS_LIBS_TMP_DIR}
        fi
    else
        git -C ${DEVOPS_LIBS_TMP_DIR} pull
    fi    

    ### Create dir and copy the base lib inside the project ###
    mkdir -p ${DEVOPS_LIBS_DIR}
    cp ${DEVOPS_LIBS_TMP_DIR}/libs/.gitignore ${DEVOPS_LIBS_DIR}
    cp ${DEVOPS_LIBS_TMP_DIR}/libs/base.sh ${DEVOPS_LIBS_DIR}
    cp ${DEVOPS_LIBS_TMP_DIR}/libs/README.md ${DEVOPS_LIBS_DIR}    

    # Copy the DevOps Libs help
    cp -r ${DEVOPS_LIBS_TMP_DIR}/README.md ${DEVOPS_LIBS_DIR}/../DEVOPS-LIBS.md

    [ ${set_e_enabled} ] || set +e # Disable set e
}

# Show using branch
echo "---> DevOps Libs branch: '${DEVOPS_LIBS_BRANCH}' (${DEVOPS_LIBS_MODE}) <---"

# Check if in on line mode
if [ ${DEVOPS_LIBS_MODE} == 'online' ]; then
    devOpsLibsClone
fi

# If base library was not yet loaded
if [ ! "${DEVOPS_LIBS_FUNCT_LOADED}" ]; then
    ### Include DevOps Libs ###
    if [ -f ${DEVOPS_LIBS_DIR}/base.sh ]; then
        source ${DEVOPS_LIBS_DIR}/base.sh
        if [ $? -ne 0 ]; then echo "Could not import DevOps Libs"; exit 1; fi
    else
        echo "Could not find DevOps Libs (offline mode?)"
        exit 1
    fi
fi

# Include project definitions case exists
test -f ${DEVOPS_LIBS_DIR}/../definitions.sh && source ${DEVOPS_LIBS_DIR}/../definitions.sh