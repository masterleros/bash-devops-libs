# Import dependencies
do.import utils.tokens

### Function to wait any in-course operation ###
# usage: waitOperation <service> <version>
function waitOperation() {

    getArgs "service version" "${@}"

    # Wait if there is a running operations for the service
    operation=$(gcloud app operations list --filter="op_resource.metadata.target:/${service}/versions/${version} AND NOT op_resource.done=true" --format="value(ID)")
    [ "${operation}" ] && gcloud app operations wait "${operation}"
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

    # Deploy with no version defined
    gcloud --quiet app deploy ${detokenizedFile}
    exitOnError "Failed to deploy the application"

    # Remove tokenized yamls
    echoInfo "Removing detokenized yaml..."
    rm ${detokenizedFile}
}
