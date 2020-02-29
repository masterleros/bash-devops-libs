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

### This funciton will map environment variables to the final name ###
# Usage: convertEnvVars <CI_COMMIT_REF_NAME> <DOLIBS_BRANCHES_DEFINITION>
# Example: [ENV]_CI_[VAR_NAME] -> [VAR NAME]  ### 
#
# DOLIBS_BRANCHES_DEFINITION: "<def1> <def2> ... <defN>"
# Definition: <branch>:<env> (example: feature/*:DEV)
# DOLIBS_BRANCHES_DEFINITION example: "feature/*:DEV fix/*:DEV develop:INT release/*:UAT bugfix/*:UAT master:PRD hotfix/*:PRD"
#
function convertEnvVars() {

    getArgs "CI_COMMIT_REF_NAME @DOLIBS_BRANCHES_DEFINITION" "${@}"

    # Set environment depending on branches definition
    for _definition in "${DOLIBS_BRANCHES_DEFINITION[@]}"; do
        _branch=${_definition%:*}
        _environment=${_definition#*:}

        # Check if matched current definition
        if [ "${CI_COMMIT_REF_NAME}" == "${_branch}" ]; then
            export CI_BRANCH_ENVIRONMENT=${_environment};
            break
        fi
    done

    # Check if found an environment
    [ "${CI_BRANCH_ENVIRONMENT}" ] || exitOnError "'${CI_COMMIT_REF_NAME}' branch naming is not supported, check your DOLIBS_BRANCHES_DEFINITION!" -1

    # Get vars to be renamed    
    vars=($(printenv | egrep -o "${CI_BRANCH_ENVIRONMENT}_CI_.*=" | awk -F= '{print $1}'))

    # If there are values to change
    if [ "${vars}" ]; then
        # Set same variable with the final name
        echoInfo "####################################################"
        for var in "${vars[@]}"; do
            var=$(echo "${var}" | awk -F '=' '{print $1}')
            new_var=$(echo "${var}" | cut -d'_' -f3-)
            echoInfo "${CI_BRANCH_ENVIRONMENT} value set: '${new_var}'"
            export "${new_var}"="${!var}"
        done
        echoInfo "####################################################"
    else
        echoInfo "### There were not found any variables for branch to environment mapping ###"
    fi
}

### This function will promote current build branch to a new one
# usage: promoteToBranch <branch>
function promoteToBranch() {

    getArgs "branch" "${@}"

    # Check if key was set
    do.validateVars GITLAB_USER_PRIVATE_KEY
    exitOnError

    do.use git

    # Set current user and email
    git config --local user.name "${GITLAB_USER_NAME}"
    git config --local user.email "${GITLAB_USER_EMAIL}"    

    # Write the private key
    #echo ${GITLAB_USER_PRIVATE_KEY}
    
    # Sync the repost
    sync https://git@"${CI_SERVER_HOST}/${CI_PROJECT_PATH}" "${branch}"
    exitOnError
}