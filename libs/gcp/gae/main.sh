# Import dependencies
do.import utils.tokens

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

    echo "service: "${service}
    # If it is requesting a specific version
    if [ "${version}" ]; then
        echo "version: "${version}

        # If it has no current version yet deployed
        if [[ $(gcloud --quiet app versions list 2>&1 | grep "${service}") ]]; then
            echo "gcloud --quiet app versions list 2>&1 | grep ${service}"
            gcloud --quiet app versions list 2>&1 | grep "${service}"

            echo "gcloud --quiet app versions list --uri --service=${service} --hide-no-traffic | grep ${version}"
            gcloud --quiet app versions list --uri --service=${service} --hide-no-traffic | grep ${version}

            # Check if same version was deployed before but is stopped, if so, delete version
            gcloud --quiet app versions list --uri --service=${service} --hide-no-traffic | grep ${version} > /dev/null
            if [ ${?} -ne 0 ]; then
                echo "return not equal to zero"
                gcloud --quiet app versions delete --service=${service} ${version}
                exitOnError "Failed to delete same version (${version}) which is currently stopped!"
            fi
        fi

        echo "deploying specific version gcloud --quiet app deploy ${detokenizedFile} --version ${version}"
        # Deploy specific version
        gcloud --quiet app deploy ${detokenizedFile} --version ${version}
    
    else 
        echo "deploying with no version defined gcloud --quiet app deploy ${detokenizedFile}"
        # Deploy with no version defined
        gcloud --quiet app deploy ${detokenizedFile}
    fi
    exitOnError "Failed to deploy the application"

    # Remove tokenized yamls
    echoInfo "Removing detokenized yaml..."
    rm ${detokenizedFile}
}