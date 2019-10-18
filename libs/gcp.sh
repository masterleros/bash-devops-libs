#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/common.sh

### Get a value from the credential json file ###
# usage: getValueFromCredential <credential_file> <key>
function getValueFromCredential {
    getArgs "credential_path key" ${@}

    # Verify if SA credential file exist
    [[ -f ${credential_path} ]] || exitOnError "Cannot find SA credential file '${credential_path}'"

    cat ${credential_path} &2
    cat ${credential_path} | grep ${key} | awk '{print $2}' | grep -o '".*"' | sed 's/"//g'    
}

### Use the service account from file ###
# usage: useSA <credential_file>
function useSA {

    getArgs "credential_path" ${@}

    # Get SA user email
    _client_mail=$(getValueFromCredential ${credential_path} client_email)

    echo "Activating Service Account '${_client_mail}'..."
    gcloud auth activate-service-account --key-file=${credential_path}
    exitOnError "Could not activate '${_client_mail}' SA"
}

### Remove the service account from system ###
# usage: revokeSA <credential_file>
function revokeSA {
    
    getArgs "credential_path" ${@}

    # Get SA user email
    _client_mail=$(getValueFromCredential ${credential_path} client_email)

    echo "Revoking Service Account '${_client_mail}'..."
    gcloud auth revoke ${_client_mail}
    exitOnError "Could not revoke '${_client_mail}' SA"
}

### Validate and set the requested project ###
# usage: useProject <project_id>
function useProject {

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
# usage: enableAPI <api_domain>
function enableAPI {

    getArgs "project api" ${@}

    gcloud --project ${project} services enable ${api}
    exitOnError "Failing enabling API: ${api}"
}

### Validate a role of current user ###
# usage: validateRole <domain> <domain_id> <member> <role>
# domains: project folder billing
function validateRole {
    
    getArgs "domain domain_id member role" ${@}

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
    foundRoles=$(${cmd} --flatten="bindings[].members" --filter "bindings.role:${role}" --format="table(bindings.members)")
    exitOnError "Check your IAM permissions (for get-iam-policy) at ${domain}: ${domain_id}"

    # If user role was not found
    echo ${foundRoles} | grep ${user} > /dev/null
    if [ $? -ne 0 ]; then
        echo "Could not find role '${role}' for user '${user}'" >&2
        return 1
    fi
    return 0
}

### Bind Role to current user ###
# usage: bindRole <domain> <domain_id> <member> <role>
# domains: project folder
function bindRole {

    getArgs "domain domain_id member role" ${@}

    # First validate if the role is already provided
    validateRole $domain $domain_id $member $role
    if [ $? -ne 0 ]; then

        # Concat the domain
        if [ ${domain} == "project" ]; then
            cmd="gcloud projects add-iam-policy-binding ${domain_id}"
        elif [ ${domain} == "folder" ]; then
            cmd="gcloud alpha resource-manager folders add-iam-policy-binding ${domain_id}"
        else
            exitOnError "Unsupported add-iam-policy-binding to '${domain}' domain" -1
        fi

        echo "Binding '${member}' role '${role}' to ${domain}: ${domain_id}..."
        if [[ "${member}" == *".iam.gserviceaccount.com" ]]; then
            ${cmd} --member serviceAccount:${member} --role ${role} > /dev/null
        else
            ${cmd} --member user:${member} --role ${role} > /dev/null
        fi

        exitOnError "Failed to bind role: '${role}' to ${domain}: ${domain_id}"    
    fi
}

### Function to deploy a gae app ###
# usage: gae_deploy <gae_yaml>
function gae_deploy {

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

### Function to deploy a gae app ###
# usage: iam_project_addrole <role> <project> <email1> <email2> ... <emailN>
function iam_project_addrole {
    
    getArgs "role project @emails" ${@}

    # For each user
    for email in ${emails[@]}; do
        bindRole project ${project} ${role} ${email}
    done
}

###############################################################################
# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    getArgs "function &@args" ${@}
    ${function} "${args[@]}"
fi
###############################################################################