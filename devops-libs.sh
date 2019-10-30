#!/bin/bash
export ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd)"

### DEVOPS LIBS BRANCH ###
DEVOPS_LIBS_DEFAULT_MODE="auto"
DEVOPS_LIBS_BRANCH="develop"
DEVOPS_LIBS_SERVER="git.gft.com"
DEVOPS_LIBS_REPO="devops-br/gitlab-gft-libs.git"
### DEVOPS LIBS DEFINITIONS ###

# Validate OS
if [[ "${OSTYPE}" != "linux-gnu" ]]; then echo "OS '${OSTYPE}' is not supported" >&2; exit -1; fi

# Function to clone the lib
function devOpsLibsClone() {

    # Check and enable set e
    set_e_enabled=${-//[^e]/}
    [ ${set_e_enabled} ] || set -e

    # If clone is local
    if [ ! "${DEVOPS_LIBS_LOCAL_MODE_PATH}" ]; then
        # Check if git is present
        if [ $(which git &> /dev/null || echo $?) ]; then echo 'ERROR: git command is required!' >&2; exit -1; fi

        ### Clone / update the libraries ###
        echo "Retrieving DevOps Libs code from '${DEVOPS_LIBS_SERVER}:${DEVOPS_LIBS_REPO}'..."

        # Get the code
        if [ ! -d ${DEVOPS_LIBS_TMP_PATH} ]; then
            if [ ${CI_JOB_TOKEN} ]; then
                git clone -b ${DEVOPS_LIBS_BRANCH} --single-branch https://gitlab-ci-token:${CI_JOB_TOKEN}@${DEVOPS_LIBS_SERVER}/${DEVOPS_LIBS_REPO} ${DEVOPS_LIBS_TMP_PATH}
            else
                git clone -b ${DEVOPS_LIBS_BRANCH} --single-branch git@${DEVOPS_LIBS_SERVER}:${DEVOPS_LIBS_REPO} ${DEVOPS_LIBS_TMP_PATH}
            fi
        else
            git -C ${DEVOPS_LIBS_TMP_PATH} pull
        fi
    fi

    echo "Installing Core library code...."

    ### Create dir and copy the Core lib inside the project ###
    mkdir -p ${DEVOPS_LIBS_PATH}
    cp ${DEVOPS_LIBS_TMP_PATH}/libs/*.* ${DEVOPS_LIBS_PATH}
    cp ${DEVOPS_LIBS_TMP_PATH}/libs/.gitignore ${DEVOPS_LIBS_PATH}

    # Copy the DevOps Libs help
    cp ${DEVOPS_LIBS_TMP_PATH}/README.md ${DEVOPS_LIBS_PATH}/../DEVOPS-LIBS.md

    [ ${set_e_enabled} ] || set +e # Disable set e
}

# If Core library was not yet loaded
if [ ! "${DEVOPS_LIBS_CORE_FUNCT}" ]; then

    ###############################
    export DEVOPS_LIBS_MODE=${1}
    export DEVOPS_LIBS_PATH="$(cd $(dirname ${BASH_SOURCE[0]}) >/dev/null 2>&1 && pwd)/devops-libs"
    export DEVOPS_LIBS_TMP_PATH="${DEVOPS_LIBS_PATH}/.libtmp/${DEVOPS_LIBS_BRANCH}"
    ###############################

    # If it was set to use local tmp folder
    if [ "${DEVOPS_LIBS_LOCAL_MODE_PATH}" ]; then
        if [ ! -d ${DEVOPS_LIBS_LOCAL_MODE_PATH} ]; then echo 'ERROR: invalid local path to clone!' >&2; exit -1; fi
        export DEVOPS_LIBS_TMP_PATH=${DEVOPS_LIBS_LOCAL_MODE_PATH}
        export DEVOPS_LIBS_MODE='local'
        echo "Using Local mode from '${DEVOPS_LIBS_LOCAL_MODE_PATH}'"        
    # Check if operation mode was specified
    elif [ ! ${DEVOPS_LIBS_MODE} ]; then # Set default mode case not provided
        if [ "${CI}" ]; then
            echo "DevOps Libs running in GitLab! setting to online mode..."
            export DEVOPS_LIBS_MODE='online'
        else
            export DEVOPS_LIBS_MODE=${DEVOPS_LIBS_DEFAULT_MODE}
        fi
    fi

    ############## VALIDATE OPERATION MODE #################    
    if [[ ${DEVOPS_LIBS_MODE} == 'auto' && ! -f ${DEVOPS_LIBS_PATH}/core.sh ]]; then 
        echo "DevOps Libs not found! forcing online mode..."
        export DEVOPS_LIBS_MODE='online'; 
    fi
    #########################################################

    # Show using branch
    echo "---> DevOps Libs branch: '${DEVOPS_LIBS_BRANCH}' (${DEVOPS_LIBS_MODE}) <---"

    # Check if in on line mode
    if [[ ${DEVOPS_LIBS_MODE} == 'online' || ${DEVOPS_LIBS_MODE} == 'local' ]]; then
        devOpsLibsClone
    fi

    ### Include DevOps Libs ###
    if [ -f ${DEVOPS_LIBS_PATH}/core.sh ]; then
        echo "Loading core library..."
        source ${DEVOPS_LIBS_PATH}/core.sh
        if [ $? -ne 0 ]; then echo "Could not import DevOps Libs"; exit 1; fi
    else
        echo "Could not find DevOps Libs (offline mode?)"
        exit 1
    fi
fi

# Include project definitions case exists
if [ -f ${DEVOPS_LIBS_PATH}/../definitions.sh ]; then
    source ${DEVOPS_LIBS_PATH}/../definitions.sh
fi