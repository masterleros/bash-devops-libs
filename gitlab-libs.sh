#!/bin/bash
#
# This script provides the common definitions and funcions to execute
# to help scripts contextualize the executions
#

### GITLAB LIBS DEFINITIONS ###
GITLAB_LIBS_DIR="$(cd $(dirname ${BASH_SOURCE[0]}) >/dev/null 2>&1 && pwd)/libs"
GITLAB_TMP_DIR="/tmp/gitlab-gft-libs"
### GITLAB LIBS DEFINITIONS ###

# Include project definitions case exists
test -f $(dirname ${BASH_SOURCE[0]})/definitions.sh && source $(dirname ${BASH_SOURCE[0]})/definitions.sh

# Validate OS
if [[ "${OSTYPE}" != "linux-gnu" ]]; then echo "OS '${OSTYPE}' is not supported" >&2; exit -1; fi

# Check if git is present
if [ $(which git &> /dev/null || echo $?) ]; then echo 'ERROR: git command is required!' >&2; exit -1; fi

### Clone / update the libraries ###
set -e
if [ ! -d ${GITLAB_TMP_DIR} ]; then
    git clone git@git.gft.com:devops-br/gitlab-gft-libs.git ${GITLAB_TMP_DIR}
else
    git -C ${GITLAB_TMP_DIR} pull 
fi
set +e

### Copy the libs inside the project ###
cp -r ${GITLAB_TMP_DIR}/libs ${GITLAB_LIBS_DIR}

### Include GitLab Libs ###
source ${GITLAB_LIBS_DIR}/common.sh