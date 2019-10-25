#!/bin/bash
eval "${importBaseLib}"

# Verify Dependencies
verifyDeps firebase

### Create firebase project case it does not exist ###
# usage: projectCreate <project> <id>
function projectCreate {

    getArgs "project id" "${@}"

    # Check if firebase project is available, else create
    firebase projects:list 2>&1 | grep ${project} | grep ${id} > /dev/null
    if [ $? -ne 0 ]; then 
        echoInfo "Creating Firebase project '${id}' in '${project}' GCP project..."
        firebase projects:addfirebase --project=${project} ${id}
        exitOnError
    else
        echoInfo "Great! Project '${id}' is already created in '${project}' GCP project!"
    fi
}

### Create firebase application case it does not exist ###
# usage: appCreate <project> <application> <type>
function appCreate {

    getArgs "project application type" "${@}"

    # Create Web Application is not exist
    firebase apps:list --project=${project} 2>&1 | grep ${type} | grep "${application}" > /dev/null
    if [ $? -ne 0 ]; then
        echoInfo "Creating ${type} Application '${application}' at '${project}' project..."
        firebase apps:create --project=${project} ${type} ${application}
        exitOnError
    else
        echoInfo "Great! ${type} Application '${application}' already exist in project '${project}'"
    fi
}

# Export internal functions
eval "${useInternalFunctions}"