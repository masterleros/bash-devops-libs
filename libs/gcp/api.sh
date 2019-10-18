### Validate a role of current user ###
# usage: gcplib.enableAPI <api_domain>
function gcplib.enableAPI {

    getArgs "project api" ${@}

    gcloud --project ${project} services enable ${api}
    exitOnError "Failing enabling API: ${api}"
}