### Validate a role of current user ###
# usage: enableAPI <api_domain>
function enableAPI {

    getArgs "project api" ${@}

    gcloud --project ${project} services enable ${api}
    exitOnError "Failing enabling API: ${api}"
}