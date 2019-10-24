#!/bin/bash
eval "${importBaseLib}"

# Verify Dependencies
verifyDeps gcloud

# Import sub-modules
importSubModules gae.sh iam.sh api.sh auth.sh

### Validate and set the requested project ###
# usage: useProject <project_id>
function useProject {

    getArgs "project" "${@}"
    
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