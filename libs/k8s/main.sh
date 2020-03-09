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
checkBins kubectl || return ${?}

### Deploy YAML file ###
# usage deployYaml <file.yaml>
function deployYaml() {
    getArgs "yaml_file"

    kubectl apply -f "${yaml_file}"
    exitOnError "The command kubectl apply could not deploy with the yaml file"
}

### Create a k8s Secret ###
# usage createSecret <namespace> <key_name> <secrets>
function createSecret() {
    getArgs "_namespace _keyName @_secrets"

    # Check and create the SA secret 
    if [ "$(kubectl get secrets -n "${_namespace}" --field-selector metadata.name="${_keyName}" -o=name)" ]; then
        echoInfo "Great! K8S Secret is already present!"
        return 0
    fi

    echoInfo "Creating K8S Secret..."
    kubectl create secret -n "${_namespace}" generic "${_keyName}" "${_secrets}"
    exitOnError "The secret could not be created"
}
