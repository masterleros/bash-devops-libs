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


### Validate a role of a email ###
# usage: validateRole <domain> <domain_id> <role> <email>
# domains: project folder billing
function validateRole {
    
    getArgs "domain domain_id role email" "${@}"

    # Validate role format
    [[ ${role} == "roles/"* ]] || exitOnError "Role must use format roles/<role>" -1    

    if [ "${domain}" == "project" ]; then
        local cmd="gcloud projects get-iam-policy ${domain_id}"
    elif [ "${domain}" == "folder" ]; then
        local cmd="gcloud alpha resource-manager folders get-iam-policy ${domain_id}"
    elif [ "${domain}" == "billing" ]; then
        local cmd="gcloud alpha billing accounts get-iam-policy ${domain_id}"
    elif [ "${domain}" == "function" ]; then
        local cmd="gcloud functions get-iam-policy ${domain_id}"        
    else
        exitOnError "Unsupported get-iam-policy from '${domain}' domain" -1
    fi

    # Execute the validation
    local foundRoles=$(${cmd} --flatten="bindings[].members" --filter "bindings.role=${role} AND bindings.members:${email}" --format="table(bindings.members)")
    exitOnError "Check your IAM permissions (for get-iam-policy) at ${domain}: ${domain_id}"

    # If email role was not found
    echo "${foundRoles}" | grep "${email}" > /dev/null
    return ${?}
}

### Bind Role to a list of emails ###
# usage: bindRole <domain> <domain_id> <role> <email1> <email2> ... <emailN>
# domains: project folder
function bindRole {

    getArgs "domain domain_id role @emails" "${@}"

    # For each user
    for email in ${emails[@]}; do

        # Validate if the role is already provided
        self validateRole "${domain}" "${domain_id}" "${role}" "${email}"
        if [ ${?} -ne 0 ]; then

            # Concat the domain
            if [ "${domain}" == "project" ]; then
                local cmd="gcloud projects add-iam-policy-binding ${domain_id}"
            elif [ "${domain}" == "folder" ]; then
                local cmd="gcloud alpha resource-manager folders add-iam-policy-binding ${domain_id}"
            elif [ "${domain}" == "function" ]; then
                local cmd="gcloud functions add-iam-policy-binding ${domain_id}"                
            else
                exitOnError "Unsupported add-iam-policy-binding to '${domain}' domain" -1
            fi

            echoInfo "Binding '${email}' role '${role}' to ${domain}: ${domain_id}..."
            if [[ "${email}" == *".iam.gserviceaccount.com" ]]; then
                ${cmd} --member serviceAccount:"${email}" --role "${role}" > /dev/null
            elif [[ "${email}" == "allUsers" ]]; then
                ${cmd} --member "${email}" --role "${role}" > /dev/null                
            else
                ${cmd} --member user:"${email}" --role "${role}" > /dev/null
            fi

            exitOnError "Failed to bind role: '${role}' to ${domain}: ${domain_id}"    
        fi
    done
}
