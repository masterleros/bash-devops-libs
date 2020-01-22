#!/bin/bash

### Find all Cloud Function definition files ###
# usage: findFiles <absolute functions folder path> <cloud function definition filename> <function name for callback> <additional args>
function findFiles() {
    getArgs "path file func @args" "${@}"

    filesFound=($(find ${path} -iname ${file} | sort))
    [ "${#filesFound[@]}" -eq 0 ] && exitOnError "Unable to locate any configuration file (${file}) to deploy the cloud function. File should be availabel under ${path}/<folder>/" -1

    for fileFound in ${filesFound[@]}; do
        ${func} ${fileFound} "${args[@]}"
    done
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
