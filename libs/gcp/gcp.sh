#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../common.sh

### Get a value from the credential json file ###
# usage: _gcplib.getValueFromCredential <credential_file> <key>
function _gcplib.getValueFromCredential {
    getArgs "credential_path key" ${@}

    # Verify if SA credential file exist
    [[ -f ${credential_path} ]] || exitOnError "Cannot find SA credential file '${credential_path}'"

    cat ${credential_path} | grep ${key} | awk '{print $2}' | grep -o '".*"' | sed 's/"//g'    
}

### Use the service account from file ###
# usage: gcplib.useSA <credential_file>
function gcplib.useSA {

    getArgs "credential_path" ${@}

    # Get SA user email
    _client_mail=$(_gcplib.getValueFromCredential ${credential_path} client_email)

    echo "Activating Service Account '${_client_mail}'..."
    gcloud auth activate-service-account --key-file=${credential_path}
    exitOnError "Could not activate '${_client_mail}' SA"
}

### Remove the service account from system ###
# usage: gcplib.revokeSA <credential_file>
function gcplib.revokeSA {
    
    getArgs "credential_path" ${@}

    # Get SA user email
    _client_mail=$(_gcplib.getValueFromCredential ${credential_path} client_email)

    echo "Revoking Service Account '${_client_mail}'..."
    gcloud auth revoke ${_client_mail}
    exitOnError "Could not revoke '${_client_mail}' SA"
}

### Validate and set the requested project ###
# usage: gcplib.useProject <project_id>
function gcplib.useProject {

    getArgs "project" ${@}
    
    # Check project    
    gcloud projects list | grep ${project} &> /dev/null
    exitOnError "Project '${project}' not found"

    # Set project
    echo "Setting current project to '${project}'..."
    gcloud config set project ${project}
    exitOnError "Failed to set working project '${project}'"
}

### Validate a role of current user ###
# usage: gcplib.enableAPI <api_domain>
function gcplib.enableAPI {

    getArgs "project api" ${@}

    gcloud --project ${project} services enable ${api}
    exitOnError "Failing enabling API: ${api}"
}

### Validate a role of a email ###
# usage: gcplib.validateRole <domain> <domain_id> <role> <email>
# domains: project folder billing
function gcplib.validateRole {
    
    getArgs "domain domain_id role email" ${@}

    # Validate role format
    [[ ${role} == "roles/"* ]] || exitOnError "Role must use format roles/<role>" -1    

    if [ ${domain} == "project" ]; then
        cmd="gcloud projects get-iam-policy ${domain_id}"
    elif [ ${domain} == "folder" ]; then
        cmd="gcloud alpha resource-manager folders get-iam-policy ${domain_id}"
    elif [ ${domain} == "billing" ]; then
        cmd="gcloud alpha billing accounts get-iam-policy ${domain_id}"
    else
        exitOnError "Unsupported get-iam-policy from '${domain}' domain" -1
    fi

    # Execute the validation
    foundRoles=$(${cmd} --flatten="bindings[].members" --filter "bindings.role=${role}" --format="table(bindings.members)")
    exitOnError "Check your IAM permissions (for get-iam-policy) at ${domain}: ${domain_id}"

    # If email role was not found
    echo ${foundRoles} | grep ${email} > /dev/null
    return $?
}

### Bind Role to a list of emails ###
# usage: gcplib.bindRole <domain> <domain_id> <role> <email1> <email2> ... <emailN>
# domains: project folder
function gcplib.bindRole {

    getArgs "domain domain_id role @emails" ${@}

    # For each user
    for email in ${emails[@]}; do

        # Validate if the role is already provided
        gcplib.validateRole ${domain} ${domain_id} ${role} ${email}
        if [ $? -ne 0 ]; then

            # Concat the domain
            if [ ${domain} == "project" ]; then
                cmd="gcloud projects add-iam-policy-binding ${domain_id}"
            elif [ ${domain} == "folder" ]; then
                cmd="gcloud alpha resource-manager folders add-iam-policy-binding ${domain_id}"
            else
                exitOnError "Unsupported add-iam-policy-binding to '${domain}' domain" -1
            fi

            echo "Binding '${email}' role '${role}' to ${domain}: ${domain_id}..."
            if [[ "${email}" == *".iam.gserviceaccount.com" ]]; then
                ${cmd} --member serviceAccount:${email} --role ${role} > /dev/null
            else
                ${cmd} --member user:${email} --role ${role} > /dev/null
            fi

            exitOnError "Failed to bind role: '${role}' to ${domain}: ${domain_id}"    
        fi
    done
}

### Function to deploy a gae app ###
# usage: gcplib.gae_deploy <gae_yaml>
function gcplib.gae_deploy {

    getArgs "GAE_YAML &GAE_VERSION" ${@}
    DESTOKENIZED_GAE_YAML="DESTOKENIZED_${GAE_YAML}"
    
    # Check if file exists
    [ -f ${GAE_YAML} ] || exitOnError "File '${GAE_YAML}' not found"

    # Get service name
    GAE_SERVICE=$(cat ${GAE_YAML} | grep -e ^service: | awk '{print $NF}')
    [ ${GAE_SERVICE} ] || GAE_SERVICE="default"

    # Replace tokens, if not present, fail
    tokenReplaceFromFile ${GAE_YAML} > ${DESTOKENIZED_GAE_YAML}

    # If it is requesting a specific version
    if [ "${GAE_VERSION}" ]; then
    
        # If it has no current version yet deployed
        if [[ $(gcloud --quiet app versions list 2>&1 | grep "${GAE_SERVICE}") ]]; then

            # Check if same version was deployed before but is stopped, if so, delete version
            gcloud --quiet app versions list --uri --service=${GAE_SERVICE} --hide-no-traffic | grep ${GAE_VERSION} > /dev/null
            if [ $? -ne 0 ]; then
                gcloud --quiet app versions delete --service=${GAE_SERVICE} ${GAE_VERSION}
                exitOnError "Failed to delete same version which is currently stopped"
            fi
        fi

        # Deploy version
        gcloud --quiet app deploy ${DESTOKENIZED_GAE_YAML} --version ${GAE_VERSION}
    
    else # No version defined
        gcloud --quiet app deploy ${DESTOKENIZED_GAE_YAML}
    fi
    exitOnError "Failed to deploy the application"
}

###############################################################################
# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    getArgs "function &@args" ${@}
    ${function} "${args[@]}"
fi
###############################################################################