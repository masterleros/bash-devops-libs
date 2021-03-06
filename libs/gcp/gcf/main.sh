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

# @description Deploy a Cloud Function
# @arg $cfName name of the cloud functions
# @arg @$parameters the cloud function parameters
# @exitcode 0 Cloud Function deployed successfuly
# @exitcode non-0 Cloud Function failed to deploy
# @example
#   deploy <function name> <aditional_parameters_array_list>
function deploy() {
    getArgs "cfName @parameters"

    gcloud functions deploy ${cfName} "${parameters[@]}" | grep -vi password
    exitOnError "Failed to deploy GCP Function ${cfName}"
}
