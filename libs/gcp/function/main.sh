#!/bin/bash

### # Get all Cloud Function definition files ###
# usage: getValuesFromFile <file> <var1> <var2> ... <varN>
function findDefinitions() {
    FUNCTIONS_FOLDER=${1}
    CF_DEFINITIONS_FILE=${2}

    CF_DEF_FILES=($(find ${FUNCTIONS_FOLDER} -iname ${CF_DEFINITIONS_FILE} -printf '%P\n' | sort))
    CF_DEF_FILES=($(find . -iname cf-definitions.conf -printf '%P\n' | sort))
    [ "${#CF_DEF_FILES[@]}" -eq 0 ] && exitOnError "Unable to locate any configuration file (${CF_DEFINITIONS_FILE}) to deploy the cloud function. File should be availabel under <ROOTDIR>/functions/<folder>/" -1
    
}

function getDefinitions() {
    [ "${#CF_DEF_FILES[@]}" -eq 0 ] && exitOnError "No definitions available. Please, make sure to call the do.gcp.function.findDefinitions before this one" -1
    echo ${CF_DEF_FILES[@]}
}

function deploy() {

}

function prepareForDeploy() {

    getArgs "FUNCTIONS_FOLDER CF_DEFINITIONS_FILE" ${@}
    findDefinitions
    
}

