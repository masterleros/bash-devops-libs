#    Copyright 2020 Leonardo Andres Morales

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#!/bin/bash

# Verify Dependencies
do.verifyDeps firebase || return ${?}

# Set firebase options
if [ "${FIREBASE_TOKEN}" ]; then FIREBASE_OPTS="--non-interactive --token ${FIREBASE_TOKEN}"; fi

# @description Check firebase project if exists
# @arg $project string GCP Project ID
# @arg $id string Firebase Project to be validated
# @exitcode 0 If the project exist
# @exitcode >0 If the project exist does not exist
# @example 
#   validateProject <project> <id>
function validateProject() {

    getArgs "project id" "${@}"

    # Get tha APP ID
    firebase "${FIREBASE_OPTS}" projects:list 2>&1 | grep "${project}" | grep "${id}" > /dev/null
    return ${?}
}

### Create firebase project case it does not exist ###
# usage: createProject <project> <id>
function createProject() {

    getArgs "project id" "${@}"

    # Check if app already exists
    self validateProject "${project}" "${id}"

    # Check if firebase project is available, else create
    if [ ${?} -ne 0 ]; then 
        echoInfo "Creating Firebase project '${id}' in '${project}' GCP project..."
        firebase "${FIREBASE_OPTS}" projects:addfirebase --project="${project}" "${id}"
        exitOnError
    else
        echoInfo "Great! Project '${id}' is already created in '${project}' GCP project!"
    fi
}

### Check firebase application if exists ###
# usage: validateApp <project> <application> <type>
function validateApp() {

    getArgs "project application type" "${@}"

    # Get tha APP ID
    firebase "${FIREBASE_OPTS}" apps:list --project="${project}" 2>&1 | grep "${type}" | grep "${application}" > /dev/null
    return ${?}
}

### Create firebase application case it does not exist ###
# usage: createApp <project> <application> <type>
function createApp() {

    getArgs "project application type" "${@}"

    # Check if app already exists
    self validateApp "${project}" "${application}" "${type}"

    # Create Web Application is not exist    
    if [ ${?} -ne 0 ]; then
        echoInfo "Creating ${type} Application '${application}' at '${project}' project..."
        firebase "${FIREBASE_OPTS}" apps:create --project="${project}" "${type}" "${application}"
        exitOnError
    else
        echoInfo "Great! ${type} Application '${application}' already exist in project '${project}'"
    fi
}

### Get an application config ts ###
# usage: getAppId <project> <type> <app>
function getAppId() {
    
    getArgs "project type app" "${@}"

    # Print the APP ID
    appType=$(echo "${type}" | tr '[:upper:]' '[:lower:]')
    firebase "${FIREBASE_OPTS}" apps:list "${type}" --project "${project}" | grep "${app}" | grep -oe 1:.*:"${appType}":[ca-z0-9]*
}

### Get an application config ts ###
# usage: getAppSdkConfig <project> <type> <file>
function getAppSdkConfig() {

    getArgs "project type app file" "${@}"

    # Get the App Id
    assign app_id=self getAppId "${project}" "${type}" "${app}"

    # if not possible to get the app id
    if [ ${?} -ne 0 ]; then echoError "Could not get '${type}' App '${app}' ID from ${project} project"; return 1; fi

    # Creating firebase firebase.config.ts key
    firebase "${FIREBASE_OPTS}" apps:sdkconfig "${type}" "${app_id}" --project "${project}" -o "${file}"

    # Removing lines starting with /
    sed -i '/^\//d' "${file}"

    # Remove empty lines
    sed -i '/^$/d' "${file}"

    # Replacing firebase.initializeApp keyword by export const firebaseConfig = {
    sed -i 's/firebase.initializeApp({/export const firebaseConfig = {/' "${file}"

    # Replacing }) keyword by }
    sed -i 's/});/}/' "${file}"
}