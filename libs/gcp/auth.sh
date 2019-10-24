### Get a value from the credential json file ###
# usage: _gcplib.getValueFromCredential <credential_file> <key>
function _gcplib.getValueFromCredential {
    getArgs "credential_path key" "${@}"

    # Verify if SA credential file exist
    [[ -f ${credential_path} ]] || exitOnError "Cannot find SA credential file '${credential_path}'"

    cat ${credential_path} | grep ${key} | awk '{print $2}' | grep -o '".*"' | sed 's/"//g'    
}

### Use the service account from file ###
# usage: useSA <credential_file>
function useSA {

    getArgs "credential_path" "${@}"

    # Get SA user email
    _client_mail=$(_gcplib.getValueFromCredential ${credential_path} client_email)

    echo "Activating Service Account '${_client_mail}'..."
    gcloud auth activate-service-account --key-file=${credential_path}
    exitOnError "Could not activate '${_client_mail}' SA"
}

### Remove the service account from system ###
# usage: revokeSA <credential_file>
function revokeSA {
    
    getArgs "credential_path" "${@}"

    # Get SA user email
    _client_mail=$(_gcplib.getValueFromCredential ${credential_path} client_email)

    echo "Revoking Service Account '${_client_mail}'..."
    gcloud auth revoke ${_client_mail}
    exitOnError "Could not revoke '${_client_mail}' SA"
}