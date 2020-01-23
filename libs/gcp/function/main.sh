#!/bin/bash

### Find all Cloud Function definition files ###
# usage: findFiles <absolute_functions_folder_path> <cloud_function_definition_filename> <callback_function_name>
function findFiles() {
    getArgs "path file callback" "${@}"

    filesFound=($(find ${path} -iname ${file} | sort))
    [ "${#filesFound[@]}" -eq 0 ] && exitOnError "Unable to locate any configuration file (${file}) to deploy the cloud function. File should be availabel under ${path}/<folder>/" -1

    for fileFound in ${filesFound[@]}; do
        ${callback} ${fileFound}
    done
}

### Apply the IAM Policy to the function ###
# usage: applyIAMPolicy <cloud_function_name>
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
# usage: deploy <function name> <aditional_parameters_array_list>
function deploy() {
    getArgs "cfName @parameters" "${@}"

    gcloud functions deploy ${cfName} ${parameters[*]} | grep -vi password
    exitOnError "Failed to deploy GCP Function ${cfName}"

    # Set IAM allowing users to invoke function
    self applyIAMPolicy ${CF_NAME}
}
