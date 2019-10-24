#!/bin/bash
#eval "${importBaseLib}"
CURRENT_DIR=something

# Verify Dependencies
verifyDeps gcloud

# Import sub-modules
source ${CURRENT_DIR}/gae.sh &&
source ${CURRENT_DIR}/iam.sh &&
source ${CURRENT_DIR}/api.sh &&
source ${CURRENT_DIR}/auth.sh
exitOnError "Error importing sub-modules"

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

# Export internal functions
eval "${useInternalFunctions}"