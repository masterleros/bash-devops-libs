#!/bin/bash

### This funciton will map environment variables to the final name ###
# Usage: convertEnvVars <CI_COMMIT_REF_NAME> <DEVOPS_LIBS_BRANCHES_DEFINITION>
# Example: [ENV]_CI_[VAR_NAME] -> [VAR NAME]  ### 
#
# DEVOPS_LIBS_BRANCHES_DEFINITION: "<def1> <def2> ... <defN>"
# Definition: <branch>:<env> (example: feature/*:DEV)
# DEVOPS_LIBS_BRANCHES_DEFINITION example: "feature/*:DEV fix/*:DEV develop:INT release/*:UAT bugfix/*:UAT master:PRD hotfix/*:PRD"
#
function convertEnvVars() {

    getArgs "CI_COMMIT_REF_NAME @DEVOPS_LIBS_BRANCHES_DEFINITION" "${@}"

    # Set environment depending on branches definition
    for _definition in "${DEVOPS_LIBS_BRANCHES_DEFINITION[@]}"; do
        _branch=${_definition%:*}
        _environment=${_definition#*:}

        # Check if matched current definition
        if [[ ${CI_COMMIT_REF_NAME} == ${_branch} ]]; then
            CI_BRANCH_ENVIRONMENT=${_environment};
            break
        fi
    done

    # Check if found an environment
    [ ${CI_BRANCH_ENVIRONMENT} ] || exitOnError "'${CI_COMMIT_REF_NAME}' branch naming is not supported, check your DEVOPS_LIBS_BRANCHES_DEFINITION!" -1

    # Get vars to be renamed    
    vars=($(printenv | egrep -o "${CI_BRANCH_ENVIRONMENT}_CI_.*=" | awk -F= '{print $1}'))

    # Set same variable with the final name
    echoInfo "####################################################"
    for var in "${vars[@]}"; do
        var=$(echo ${var} | awk -F '=' '{print $1}')
        new_var=$(echo ${var} | cut -d'_' -f3-)
        echoInfo "${CI_BRANCH_ENVIRONMENT} value set: '${new_var}'"
        export ${new_var}="${!var}"
    done
    echoInfo "####################################################"
}

### Synchronize a GIT repository with current code
# usage: sync <git_url>
function sync() {

    getArgs "url branch" "${@}"

    # Verify Dependencies
    verifyDeps git || return ${?}

    # Remote repository to sync and current branch
    remote="gitsync"
    
    # Add upstream case is not yet present
    if [ "$(git remote -v | grep ${remote})" ]; then
        git remote remove ${remote}
    fi

    # Add remote
    git remote add ${remote} ${url}
    exitOnError

    # Push remote
    echoInfo "Sending code to the remote repository '${url}' at branch '${branch}'"
    if [[ "${branch}" != "${CI_COMMIT_REF_NAME}" ]]; then
        # Get the origin code from the required branch
        git fetch origin ${branch}

        # Push to remote
        git push ${remote} ${branch}
    else
        # Push head to remote
        git push ${remote} HEAD:refs/heads/${branch}
    fi
    exitOnError

    # Remove upstream remote
    git remote remove ${remote}
}
