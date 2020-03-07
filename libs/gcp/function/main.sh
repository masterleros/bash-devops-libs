#!/bin/bash

# Verify Dependencies
verifyDeps gcloud || return ${?}

### Deploy Cloud Function ###
# usage: deploy <function name> <aditional_parameters_array_list>
function deploy() {
    getArgs "cfName @parameters"

    gcloud functions deploy ${cfName} ${parameters[*]} | grep -vi password
    exitOnError "Failed to deploy GCP Function ${cfName}"
}
