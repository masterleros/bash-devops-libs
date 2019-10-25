### Function to deploy a gae app ###
# usage: gae_deploy <gae_yaml>
function gae_deploy {

    getArgs "GAE_YAML &GAE_VERSION" "${@}"
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
            if [ ${?} -ne 0 ]; then
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