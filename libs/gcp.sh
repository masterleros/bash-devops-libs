#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/common.sh

### Use the service account from file ###
# usage: useSA <credential_file>
function useSA {

    getArgs "credential_path" ${@}

    # Verify if SA credential file exist
    [[ -f ${credential_path} ]] || exitOnError "Cannot find SA credential file '${credential_path}'"

    # Get SA user
    client_mail=$(cat ${credential_path} | grep client_email | awk '{print $2}' | grep -o '".*"' | sed 's/"//g')

    echo "Activating Service Account ${client_mail}..."
    gcloud auth activate-service-account --key-file=${credential_path}
    exitOnError "Could not activate ${client_mail} SA"
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
        echo "Could not find role '${role}' for user '${user}'"
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
# usage: gae_deploy <service> <>
function gae_deploy {

    getArgs "GAE_SERVICE" ${@}
    GAE_VERSION=$2 # optional argument

    exitOnError "TODO: get GAE_SERVICE from yaml file!" -1    

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
        gcloud --quiet app deploy ${GAE_YAML} --version ${GAE_VERSION}
    # No version defined
    else
        gcloud --quiet app deploy ${GAE_YAML}
    fi
    exitOnError "Failed to deploy the application"
}

###############################################################################
# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    function=${1}
    shift
    $function "${@}"
fi
###############################################################################