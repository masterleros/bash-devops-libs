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


# Import dependencies
do.use utils.tokens


# @description Deploys an Google AppEngine application
# @arg $path to the description of the AppEngine application
# @arg $[path] optional version idenfitier
# @exitcode 0 GAE app deployed
# @exitcode non-0 GAE app not deployed
# @example
#    deploy <path> [version]
function deploy() {

    getArgs "path version="
    
    # Detokenize the file
    echoInfo "Creating detokenized yaml..."
    local detokenizedFile=$(dirname "${path}")/detokenized_$(basename "${path}")
    utils.tokens.replaceFromFileToFile "${path}" "${detokenizedFile}" true
    exitOnError "It was not possible to replace all the tokens in '${path}', please check if values were exported."

    # Get service name
    service=$(< "${detokenizedFile}" grep -e ^service: | awk '{print $NF}')
    [ "${service}" ] || service="default"

    # If it is requesting a specific version
    if [ "${version}" ]; then
    
        # If it has no current version yet deployed
        if [ "$(gcloud --quiet app versions list 2>&1 | grep ${service})" ]; then

            # Check if same version was deployed before but is stopped, if so, delete version
            gcloud --quiet app versions list --uri --service="${service}" --hide-no-traffic | grep "${version}" > /dev/null
            if [ ${?} -ne 0 ]; then
                gcloud --quiet app versions delete --service="${service}" "${version}"
                exitOnError "Failed to delete same version (${version}) which is currently stopped!"
            fi
        fi

        # Deploy specific version
        gcloud --quiet app deploy "${detokenizedFile}" --version "${version}"
    
    else 
        # Deploy with no version defined
        gcloud --quiet app deploy "${detokenizedFile}"
    fi
    exitOnError "Failed to deploy the application"

    # Remove tokenized yamls
    echoInfo "Removing detokenized yaml..."
    rm "${detokenizedFile}"
}
