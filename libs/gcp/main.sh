#!/bin/bash

# Verify Dependencies
verifyDeps gcloud || return ${?}

# Import sub-modules
importSubModules gae iam api auth firestore storage

### Validate and set the requested project ###
# usage: useProject <project_id>
function useProject() {

    getArgs "project" "${@}"
    
    # Check project    
    gcloud projects list | grep ${project} &> /dev/null
    exitOnError "Project '${project}' not found"

    # Set project
    echoInfo "Setting current project to '${project}'..."
    gcloud config set project ${project}
    exitOnError "Failed to set working project '${project}'"
}
