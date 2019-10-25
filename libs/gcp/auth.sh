### Get a value from the credential json file ###
# usage: _gcplib.getValueFromCredential <credential_file> <key>
function _gcplib.getValueFromCredential {
    getArgs "credential_path key" "${@}"

    # Verify if SA credential file exist
    [[ -f ${credential_path} ]] || exitOnError "Cannot find SA credential file '${credential_path}'"

    cat ${credential_path} | grep ${key} | awk '{print $2}' | grep -o '".*"' | sed 's/"//g'    
}

### Use the service account from file ###
# usage: createSA <project> <sa_id> [description]
function createSA {

    getArgs "project sa_id &description" "${@}"

    # Create sa email value
    sa_mail="${sa_id}@${project}.iam.gserviceaccount.com"

    gcloud --project ${project} iam service-accounts list | grep ${sa_mail} > /dev/null
    if [ $? -ne 0 ]  ; then
        echoInfo "Creating Service account '${sa_mail}'..."
        gcloud --project ${project} iam service-accounts create ${sa_id} --display-name ${description}
        exitOnError
    else
        echoInfo "Service Account '${sa_mail}' already created!"
    fi
}

### Use the service account from file ###
# usage: useSA <credential_file>
function useSA {

    getArgs "credential_path" "${@}"

    # Get SA user email
    _client_mail=$(_gcplib.getValueFromCredential ${credential_path} client_email)

    echoInfo "Activating Service Account '${_client_mail}'..."
    gcloud auth activate-service-account --key-file=${credential_path}
    exitOnError "Could not activate '${_client_mail}' SA"
}

### Remove the service account from system ###
# usage: revokeSA <credential_file>
function revokeSA {
    
    getArgs "credential_path" "${@}"

    # Get SA user email
    _client_mail=$(_gcplib.getValueFromCredential ${credential_path} client_email)

    echoInfo "Revoking Service Account '${_client_mail}'..."
    gcloud auth revoke ${_client_mail}
    exitOnError "Could not revoke '${_client_mail}' SA"
}

### Create a service account credential json file
# usage: createCredential <project> <credential_path> <sa_mail>
function createCredential {

    getArgs "project credential_path sa_mail" "${@}"

    # Check if account is already created
    if [ -f ${credential_path} ]; then  
        echoInfo "Creating '${sa_mail}' credential..."
        if [ -z "$(cat ${credential_path} | grep ${sa_mail})" ]; then   
            exitOnError "The file ${credential_path} is used by other account, please rename/move it" -1
        fi
        echoInfo "Great! Credentials are already present on your environment"
    else
        ## Create/Download credentials ######
        gcloud iam service-accounts keys create ${credential_path} --iam-account ${sa_mail} --user-output-enabled false
        exitOnError "Failed creating/downloading key for '${sa_mail}'"
    fi
}
