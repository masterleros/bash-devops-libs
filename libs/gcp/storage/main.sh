# Verify Dependencies
verifyDeps gsutil

### Check bucket exists ###
# usage: validateBucket <project> <bucket>
function validateBucket() {

    getArgs "project bucket" "${@}"

    # Get tha APP ID
    gsutil ls -p ${project} | grep ${bucket} > /dev/null
    return ${?}
}