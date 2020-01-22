#!/bin/bash

# Import required libs
do.import utils.tokens utils.configs

### Find all Cloud Function definition files ###
# usage: findDefinitions <absolute functions folder path> <cloud function definition filename>
function findDefinitions() {
    getArgs "FUNCTIONS_FOLDER CF_DEFINITIONS_FILE" "${@}"

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

### Prepare for Deploying Cloud Function ###
# usage: prepareForDeploy <functions folder> <aditional parameters array list>
function prepareForDeploy() {

    getArgs "FUNCTIONS_FOLDER CF_DEFINITIONS_FILE ENV_YML_SOURCE_FILE" "${@}"

    # Find all Cloud Function definition files
    findDefinitions ${FUNCTIONS_FOLDER} ${CF_DEFINITIONS_FILE}

    # Retrieving the definition files found do.gcp.function.
    CF_DEFINITIONS_FILES=($(getDefinitions))

    for cfDefFiles in ${CF_DEFINITIONS_FILES[@]}; do
        CF_ROOTDIR=$(dirname ${cfDefFiles})
        CF_FILE=$(basename ${cfDefFiles})

        # Get the cf_definition.conf file and replace variables by final values
        do.utils.tokens.replaceFromFileToFile ${CF_ROOTDIR}/${CF_FILE} ${CF_ROOTDIR}/${CF_FILE}
        exitOnError "Fail to replace variables in '${CF_ROOTDIR}/${CF_FILE}'"

        # Parse the config file and extract required info
        do.utils.configs.getValuesFromFile ${CF_ROOTDIR}/${CF_FILE} CF_NAME

        # Extracting the additional parameters for Cloud Functions Deploy
        do.utils.configs.getParametersFromFile ${CF_ROOTDIR}/${CF_FILE} CF_PARAMETERS

        # Tokenize template environment variables file
        do.utils.tokens.replaceFromFileToFile ${CF_ROOTDIR}/${ENV_YML_SOURCE_FILE} ${CF_ROOTDIR}/detokenized-env.yml
        exitOnError "Fail to replace variables in '${CF_ROOTDIR}/detokenized-env.yaml'"

        # Deploy Function
        deploy ${CF_NAME} ${CF_PARAMETERS}

        # Set IAM allowing users to invoke function
        applyIAMPolicy ${CF_NAME}
    done
}
