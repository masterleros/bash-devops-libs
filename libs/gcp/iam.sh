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
    foundRoles=$(${cmd} --flatten="bindings[].members" --filter "bindings.role=${role} AND bindings.members:${email}" --format="table(bindings.members)")
    exitOnError "Check your IAM permissions (for get-iam-policy) at ${domain}: ${domain_id}"

    # If email role was not found
    echo "${foundRoles}" | grep "${email}" > /dev/null
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
        echo "gcplib.validateRole ${domain} ${domain_id} ${role} ${email}"
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