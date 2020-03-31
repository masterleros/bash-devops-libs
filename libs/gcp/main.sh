#!/bin/bash
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


# Verify Dependencies
checkBins gcloud || return ${?}

# @description Validate and set the requested project
# @arg $project_id id of the project
# @exitcode 0 Project set
# @exitcode 1 Project not found
# @example
#   useProject <project_id>
function useProject() {

    getArgs "project"
    
    # Check project    
    gcloud projects list | grep "${project}" &> /dev/null
    exitOnError "Project '${project}' not found"

    # Set project
    echoInfo "Setting current project to '${project}'..."
    gcloud config set project "${project}"
    exitOnError "Failed to set working project '${project}'"
}

# @description Set default configuration for project zone
# @arg $zone desired GCP zone
# @example
#   setDefaultZone us-west1-a
function setDefaultZone() {
    getArgs "zone"

    # Set zone
    gcloud config set compute/zone "${zone}"
}
