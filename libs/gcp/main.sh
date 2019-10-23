#!/bin/bash
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
#source ${CURRENT_DIR}/../common.sh
source ${CURRENT_DIR}/gae.sh
source ${CURRENT_DIR}/iam.sh
source ${CURRENT_DIR}/api.sh
source ${CURRENT_DIR}/auth.sh

### Validate and set the requested project ###
# usage: useProject <project_id>
function useProject {

    getArgs "project" ${@}
    
    # Check project    
    gcloud projects list | grep ${project} &> /dev/null
    exitOnError "Project '${project}' not found"

    # Set project
    echo "Setting current project to '${project}'..."
    gcloud config set project ${project}
    exitOnError "Failed to set working project '${project}'"
}

###############################################################################
# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    getArgs "function &@args" ${@}
    ${function} "${args[@]}"
fi
###############################################################################