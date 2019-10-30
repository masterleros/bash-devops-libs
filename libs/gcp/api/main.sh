### Validate a role of current user ###
# usage: enable <api_domain>
function enable {

    getArgs "project api" "${@}"

    gcloud --project ${project} services enable ${api}
    exitOnError "Failing enabling API: ${api}"
}