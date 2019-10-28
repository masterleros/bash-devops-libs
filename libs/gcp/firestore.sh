### Validate if the project is firestore enabled ###
# usage: firestoreEnabledProject <project>
function firestoreEnabledProject {
    getArgs "project" "${@}"
    gcloud --quiet --project=${project} beta firestore operations list > /dev/null
    return ${?}
}