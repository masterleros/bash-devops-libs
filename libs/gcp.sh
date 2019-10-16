#!/bin/bash
echo "Hello from '${BASH_SOURCE[0]}'"
source $(dirname ${BASH_SOURCE[0]})/common.sh

# Use the service account from file
function useSA {

    echo "Hello from useSA!"

    credential_path=$1

    # Verify if SA credential file exist
    [[ -f ${credential_path} ]] || exitOnError "Cannot find SA credential file '${1}'"

    # Get SA user
    client_mail=$(cat ${credential_path} | grep client_email | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')

    echo "Activating Service Account ${client_mail}..."
    gcloud auth activate-service-account --key-file=${credential_path}
    exitOnError "Could not activate ${client_mail} SA"
}

# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    function=${1}
    shift
    $function "${@}"
fi