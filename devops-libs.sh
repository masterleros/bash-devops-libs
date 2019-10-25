#!/bin/bash
#
# This script provides the common definitions and funcions to execute
# to help scripts contextualize the executions
#
export ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd)"

### GITLAB LIBS BRANCH ###
GITLAB_LIBS_BRANCH="feature/lib-updates"
GITLAB_LIBS_SERVER="git.gft.com"
GITLAB_LIBS_REPO="devops-br/gitlab-gft-libs.git"
### GITLAB LIBS DEFINITIONS ###

###############################
export GITLAB_LIBS_MODE=${1}
export GITLAB_LIBS_DIR="${ROOTDIR}/scripts/devops-libs"    
export GITLAB_TMP_DIR="${GITLAB_LIBS_DIR}/.libtmp/${GITLAB_LIBS_BRANCH}"
###############################

# Validate OS
if [[ "${OSTYPE}" != "linux-gnu" ]]; then echo "OS '${OSTYPE}' is not supported" >&2; exit -1; fi

# Check if the execution in on GitLab
if [ "${CI}" ]; then echo "---> Running on GitLab CI/CD <---"; fi

############## VALIDATE OPERATION MODE #################
if [ ! ${GITLAB_LIBS_MODE} ]; then export GITLAB_LIBS_MODE='auto'; fi # Set default mode case not provided
if [[ ${GITLAB_LIBS_MODE} == 'auto' && ! -f ${GITLAB_LIBS_DIR}/base.sh ]]; then 
    echo "DevOps Libs not found! forcing online mode..."
    export GITLAB_LIBS_MODE='online'; 
fi
#########################################################

# Function to clone the lib
function cloneLib() {

    # Check if git is present
    if [ $(which git &> /dev/null || echo $?) ]; then echo 'ERROR: git command is required!' >&2; exit -1; fi

    ### Clone / update the libraries ###
    set_e_enabled=${-//[^e]/}
    [ ${set_e_enabled} ] || set -e # Enable set e

    echo "Retrieving GitLab Libs code...."

    # Get the code
    if [ ! -d ${GITLAB_TMP_DIR} ]; then
        if [ ${CI_JOB_TOKEN} ]; then
            git clone -b ${GITLAB_LIBS_BRANCH} --single-branch https://gitlab-ci-token:${CI_JOB_TOKEN}@${GITLAB_LIBS_SERVER}/${GITLAB_LIBS_REPO} ${GITLAB_TMP_DIR}
        else
            git clone -b ${GITLAB_LIBS_BRANCH} --single-branch git@${GITLAB_LIBS_SERVER}:${GITLAB_LIBS_REPO} ${GITLAB_TMP_DIR}
        fi
    else
        git -C ${GITLAB_TMP_DIR} pull
    fi    

    ### Create dir and copy the base lib inside the project ###
    mkdir -p ${GITLAB_LIBS_DIR}
    cp ${GITLAB_TMP_DIR}/libs/.gitignore ${GITLAB_LIBS_DIR}
    cp ${GITLAB_TMP_DIR}/libs/base.sh ${GITLAB_LIBS_DIR}
    cp ${GITLAB_TMP_DIR}/libs/README.md ${GITLAB_LIBS_DIR}    

    # Copy the GitLab Libs help
    cp -r ${GITLAB_TMP_DIR}/README.md $(dirname ${BASH_SOURCE[0]})/GITLAB-LIBS.md

    [ ${set_e_enabled} ] || set +e # Disable set e
}

# Show using branch
echo "---> GitLab Libs branch: '${GITLAB_LIBS_BRANCH}' (${GITLAB_LIBS_MODE}) <---"

# Check if in on line mode
if [ ${GITLAB_LIBS_MODE} == 'online' ]; then
    cloneLib
fi

# If base library was not yet loaded
if [ ! "${GITLAB_LIBS_FUNCT_LOADED}" ]; then
    ### Include GitLab Libs ###
    if [ -f ${GITLAB_LIBS_DIR}/base.sh ]; then
        source ${GITLAB_LIBS_DIR}/base.sh
        if [ $? -ne 0 ]; then echo "Could not import GitLab Libs"; exit 1; fi
    else
        echo "Could not find GitLab Libs (offline mode?)"
        exit 1
    fi
fi

# Include project definitions case exists
test -f $(dirname ${BASH_SOURCE[0]})/definitions.sh && source $(dirname ${BASH_SOURCE[0]})/definitions.sh