#!/bin/bash
#
# This script provides the common definitions and funcions to execute
# to help scripts contextualize the executions
#
ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd )"

### GITLAB LIBS DEFINITIONS ###
GITLAB_LIBS_BRANCH="master"
GITLAB_LIBS_SERVER="git.gft.com"
GITLAB_LIBS_REPO="devops-br/gitlab-gft-libs.git"
GITLAB_LIBS_DIR="${ROOTDIR}/scripts/libs"
GITLAB_TMP_DIR="/tmp/gitlab-gft-libs/${GITLAB_LIBS_BRANCH}"
### GITLAB LIBS DEFINITIONS ###

# Include project definitions case exists
test -f $(dirname ${BASH_SOURCE[0]})/definitions.sh && source $(dirname ${BASH_SOURCE[0]})/definitions.sh

# Validate OS
if [[ "${OSTYPE}" != "linux-gnu" ]]; then echo "OS '${OSTYPE}' is not supported" >&2; exit -1; fi

# Check if the execution in on GitLab
if [ "${CI}" ]; then echo "---> Running on GitLab CI/CD <---"; fi

# Check if not in off line mode
if [ "${1}" != "offline" ]; then 

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

    echo "*** GitLab Libs branch: '${GITLAB_LIBS_BRANCH}' ***"

    ### Create dir and copy the libs inside the project ###
    mkdir -p ${GITLAB_LIBS_DIR} && cp -r ${GITLAB_TMP_DIR}/libs/* ${GITLAB_LIBS_DIR}

    # Make libraries executable
    find ${GITLAB_LIBS_DIR} -name 'main.sh' -exec chmod +x {} \;

    [ ${set_e_enabled} ] || set +e # Disable set e
fi

### Include GitLab Libs ###
source ${GITLAB_LIBS_DIR}/base.sh
if [ $? -ne 0 ]; then echo "Could not import GitLab Libs"; exit 1; fi