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
checkBins terraform || return ${?}

### Init terraform plan
# usage: init <terraform path>
function init() {

    getArgs "terraform_path bucket= prefix="
    
    cd "${terraform_path}"
    if [[ ${bucket} ]] && [[ ${prefix} ]]; then
      # Passing backEnd config on the fly
      echoInfo "Initializing GCP backEnd from given config."
      terraform init -backend-config="bucket=${bucket}" -backend-config="prefix=${prefix}"
      exitOnError "Failed to initialize terraform"
    else
      terraform init
      exitOnError "Failed to initialize terraform"
    fi
    
}

### Apply terraform plan
# usage: apply <terraform path>
function apply() {
    
    getArgs "terraform_path quiet="

    cd "${terraform_path}"

    # Case executing in automation, execute with auto approve
    if [ "${CI}" ] || [ "${quiet}" == true ] ; then
        terraform plan
        terraform apply -auto-approve        
    else
       terraform apply
    fi

    exitOnError "Failed to execute 'apply' terraform command"
}

### Create the backend configuration for GCP
# usage: createBackEndGCP <terraform path> <bucket> <prefix>
function createBackEndGCP() {

    getArgs "terraform_path bucket prefix"

    # Validate required vars and dependencies
    checkVars GOOGLE_APPLICATION_CREDENTIALS
    exitOnError "'GOOGLE_APPLICATION_CREDENTIALS' Variable must be set for backend configuration"

    # Create backend config
    cat > "${terraform_path}"/backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${bucket}"
    credentials = "${GOOGLE_APPLICATION_CREDENTIALS}"
    prefix = "terraform/${prefix}/state"
  }
}
EOF
exitOnError "It was not possible to create the backend.tf file"

}
