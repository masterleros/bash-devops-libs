#!/bin/bash

### Find all Cloud Function definition files ###
# usage: findDefinitions <absolute functions folder path> <cloud function definition filename>
function findDefinitions() {
    FUNCTIONS_FOLDER=${1}
    CF_DEFINITIONS_FILE=${2}

    #CF_DEF_FILES=($(find ${FUNCTIONS_FOLDER} -iname ${CF_DEFINITIONS_FILE} -printf '%P\n' | sort))
    CF_DEF_FILES=($(find ${FUNCTIONS_FOLDER} -iname ${CF_DEFINITIONS_FILE} | sort))
    [ "${#CF_DEF_FILES[@]}" -eq 0 ] && exitOnError "Unable to locate any configuration file (${CF_DEFINITIONS_FILE}) to deploy the cloud function. File should be availabel under ${FUNCTIONS_FOLDER}/<folder>/" -1
   
}

### Apply the IAM Policy to the function ###
# usage: applyIAMPolicy <function name>
function applyIAMPolicy {
    getArgs "cfName" "${@}"
    # Set IAM allowing users to invoke function
    gcloud functions add-iam-policy-binding ${cfName} \
    --quiet \
    --member="allUsers" \
    --role="roles/cloudfunctions.invoker"
    exitOnError "Failed to apply IAM policy to ${cfName}"
}

### Deploy Cloud Function ###
# usage: deploy <function name> <aditional parameters array list>
function deploy() {
    getArgs "cfName @parameters" "${@}"
    echo "gcloud functions deploy ${cfName} ${parameters[*]} | grep -vi password"
    #exitOnError "Failed to deploy GCP Function ${cfName}"
}

### Returns all Cloud Function definition files found in findDefinitions function ###
# usage: getDefinitions
function getDefinitions() {
    [ "${#CF_DEF_FILES[@]}" -eq 0 ] && exitOnError "No definitions available. Please, make sure to call the do.gcp.function.findDefinitions before this one" -1
    echo ${CF_DEF_FILES[@]}
}
