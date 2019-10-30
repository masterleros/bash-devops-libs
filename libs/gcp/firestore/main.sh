### Validate if the project is firestore enabled ###
# usage: enabledProject <project>
function enabledProject {
    getArgs "project" "${@}"
    gcloud --quiet --project=${project} beta firestore operations list > /dev/null
    return ${?}
}