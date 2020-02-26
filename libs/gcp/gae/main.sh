# Import dependencies
do.import utils.tokens

### Function to wait any in-course operation ###
# usage: waitOperation <service> <version>
function waitOperation() {

    getArgs "service version" "${@}"

    # Wait if there is a running operations for the service
    operation=$(cloud app operations list --filter="op_resource.metadata.target:/${service}/versions/${version} AND NOT op_resource.done=true" --format="value(ID)")
    [ "${operation}" ] && gcloud app operations wait "${operation}""
}

### Function to deploy a gae app ###
# usage: deploy <path> [version]
function deploy {

    getArgs "path &version" "${@}"
    
    # Detokenize the file
    echoInfo "Creating detokenized yaml..."
    local detokenizedFile="$(dirname ${path})/detokenized_$(basename ${path})"
    do.utils.tokens.replaceFromFileToFile ${path} ${detokenizedFile} true
    exitOnError "It was not possible to replace all the tokens in '${path}', please check if values were exported."

    # Get service name
    service=$(cat ${detokenizedFile} | grep -e ^service: | awk '{print $NF}')
    [ ${service} ] || service="default"

    # If it is requesting a specific version
    if [ "${version}" ]; then
        
        ### NEW CODE ###
        # Wait any pending operation
        self waitOperation "${service}" "${version}"

        # Get the status of current version    
        status=$(gcloud app versions list --filter="SERVICE=${service} AND VERSION.ID=${version} AND TRAFFIC_SPLIT=0" --format="value(SERVING_STATUS)")

        # If it exists and is stopped, delete version
        if [ "${status}" == "STOPPED" ]; then
            gcloud --quiet app versions delete --service=${service} ${version}
            exitOnError "Failed to delete same version (${version}) which is currently stopped!"

            # Wait the operation
            self waitOperation "${service}" "${version}"
        fi
        ### NEW CODE ###

        ### OLD CODE ###
        # # If it has no current version yet deployed
        # #serving=$(gcloud app versions list --filter="SERVICE=${service} AND VERSION.ID=${version}" --format="value(SERVING_STATUS)")
        
        # # Check if same version was deployed before but is stopped, if so, delete version
        # if [[ $(gcloud --quiet app versions list 2>&1 | grep "${service}") ]]; then
            
        #     gcloud --quiet app versions list --uri --service=${service} --hide-no-traffic | grep ${version} > /dev/null
        #     if [ ${?} -ne 0 ]; then
        #         gcloud --quiet app versions delete --service=${service} ${version}
        #         exitOnError "Failed to delete same version (${version}) which is currently stopped!"
        #     fi
        # fi
        ### OLD CODE ###

        # Deploy specific version
        gcloud --quiet app deploy ${detokenizedFile} --version ${version}
    
    else 
        # Deploy with no version defined
        gcloud --quiet app deploy ${detokenizedFile}
    fi
    exitOnError "Failed to deploy the application"

    # Remove tokenized yamls
    echoInfo "Removing detokenized yaml..."
    rm ${detokenizedFile}
}
