#!/bin/bash
eval "${headLibScript}"

# Verify Dependencies
verifyDeps terraform

### Synchronize a GIT repository with current code
# usage: apply <terraform path>
function apply() {
    
    getArgs "terraform_path" "${@}"

    cd ${terraform_path}

    # Case executing in automation, execute with auto approve
    if [ "${CI}" ]; then
        terraform plan
        terraform apply -auto-approve        
    else
       terraform apply
    fi

    exitOnError "Failed to execute 'apply' terraform command"
}

# Export internal functions
eval "${footLibScript}"