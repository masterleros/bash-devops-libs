### Function to deploy a gae app ###
# usage: gae_deploy <yaml> [version]
function gae_deploy {

    getArgs "yaml &version" "${@}"    
    
    # Check if file exists
    [ -f ${yaml} ] || exitOnError "File '${yaml}' not found"

    # Get service name
    service=$(cat ${yaml} | grep -e ^service: | awk '{print $NF}')
    [ ${service} ] || service="default"

    # If it is requesting a specific version
    if [ "${version}" ]; then
    
        # If it has no current version yet deployed
        if [[ $(gcloud --quiet app versions list 2>&1 | grep "${service}") ]]; then

            # Check if same version was deployed before but is stopped, if so, delete version
            gcloud --quiet app versions list --uri --service=${service} --hide-no-traffic | grep ${version} > /dev/null
            if [ ${?} -ne 0 ]; then
                gcloud --quiet app versions delete --service=${service} ${version}
                exitOnError "Failed to delete same version (${version}) which is currently stopped!"
            fi
        fi

        # Deploy specific version
        gcloud --quiet app deploy ${yaml} --version ${version}
    
    else 
        # Deploy with no version defined
        gcloud --quiet app deploy ${yaml}
    fi
    exitOnError "Failed to deploy the application"
}