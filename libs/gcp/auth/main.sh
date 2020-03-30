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

# @description Get a value from the credential json file
# @return User e-mail
# @example
#   assign currentUserEmail=getCurrentUser()
function getCurrentUser() {
    _return=$(gcloud --quiet config list account --format "value(core.account)")
    [ "${_return}" ]
    return ${?}
}

# @description Get a value from the credential json file
# @arg $credential_file path to a GCP credential file
# @arg $key key inside the credential file json
# @return Desired key value
# @example
#   assign key_value=getValueFromCredential <credential_file> <key>
function getValueFromCredential {
    getArgs "credential_path key"

    # Verify if SA credential file exist
    [ -f "${credential_path}" ] || exitOnError "Cannot find SA credential file '${credential_path}'"

    _return=$(< "${credential_path}" grep "${key}" | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')
    return ${?}
}

# @description Create a service account with the given parameters
# @arg $project id of the project
# @arg $sa_id id of the service account
# @arg [$description] optional description
# @exitcode 0 Successfuly created SA
# @exitcode non-0 Failed to create SA
# @example
#   createSA <project> <sa_id> [description]
function createSA {

    getArgs "project sa_id description="

    # Create sa email value
    sa_mail="${sa_id}@${project}.iam.gserviceaccount.com"

    gcloud --project "${project}" iam service-accounts list | grep "${sa_mail}" > /dev/null
    if [ ${?} -ne 0 ]  ; then
        echoInfo "Creating Service account '${sa_mail}'..."
        gcloud --project "${project}" iam service-accounts create "${sa_id}" --display-name "${description}"
        exitOnError
    else
        echoInfo "Service Account '${sa_mail}' already created!"
    fi
}

# @description Validates and use the service account from file
# @arg $credential_file path to a GCP credential file
# @exitcode 0 Successfuly set SA
# @exitcode non-0 Failed to set SA
# @example
#   useSA <credential_file>
function useSA {

    getArgs "credential_path"

    # Get SA user email
    assign _client_mail=self getValueFromCredential "${credential_path}" client_email
    exitOnError "Could not get Service Account information"

    echoInfo "Activating Service Account '${_client_mail}'..."
    gcloud auth activate-service-account --key-file="${credential_path}"
    exitOnError "Could not activate '${_client_mail}' SA"
}

# @description Remove the service account from system
# @arg $credential_file path to a GCP credential file
# @exitcode 0 Successfuly revoked SA
# @exitcode non-0 Failed to revoked SA
# @example
#   revokeSA <credential_file>
function revokeSA {

    getArgs "credential_path"

    # Get SA user email
    assign _client_mail=self getValueFromCredential "${credential_path}" client_email
    exitOnError "Could not get Service Account information"

    echoInfo "Revoking Service Account '${_client_mail}'..."
    gcloud auth revoke "${_client_mail}"
    exitOnError "Could not revoke '${_client_mail}' SA"
}

# @description Create a service account credential json file
# @arg $project id of the project
# @arg $credential_path path to create a GCP credential file
# @arg $sa_mail email of the SA
# @exitcode 0 Successfuly created SA
# @exitcode non-0 Failed to created SA
# @example
#   createCredential <project> <credential_path> <sa_mail>
function createCredential {

    getArgs "project credential_path sa_mail"

    # Check if account is already created
    if [ -f "${credential_path}" ]; then  
        echoInfo "Creating '${sa_mail}' credential..."
        if [ -z $(< "${credential_path}" grep "${sa_mail}") ]; then   
            exitOnError "The file ${credential_path} is used by other account, please rename/move it" -1
        fi
        echoInfo "Great! Credentials are already present on your environment"
    else
        ## Create/Download credentials ######
        gcloud iam service-accounts keys create "${credential_path}" --iam-account "${sa_mail}" --user-output-enabled false
        exitOnError "Failed creating/downloading key for '${sa_mail}'"
    fi
}

# @description Delete a SA credential of the project
# @arg $project id of the project
# @arg $credential_path path to delete a GCP credential file
# @arg $sa_mail email of the SA
# @exitcode 0 Successfuly delete SA
# @exitcode non-0 Failed to delete SA
# @example
#   deleteCredential <project> <credential_path> <sa_mail>
function deleteCredential {

    getArgs "project credential_path sa_mail"

    # Check if account is already created
    if [ -f "${credential_path}" ]; then
        echo "Deleting '${sa_mail}' credential..."

        # Get SA user email
        assign _private_key_id=self getValueFromCredential "${credential_path}" private_key_id
        exitOnError "Could not get Service Account information"

        # Revoke account locally
        gcloud auth revoke "${sa_mail}" &> /dev/null

        # Delete local file
        rm "${credential_path}" &> /dev/null

        # Delete key on SA
        gcloud --quiet iam service-accounts keys delete "${_private_key_id}" --iam-account "${sa_mail}"
        exitOnError "Failed to delete the key"
    else
        exitOnError "Credential file ${credential_path} not found", -1
    fi
}
