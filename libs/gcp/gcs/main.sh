#    Copyright 2020 Leonardo Andres Morales

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#!/bin/bash

# Verify Dependencies
do.verifyDeps gsutil

### Check bucket exists ###
# usage: validateBucket <project> <bucket>
function validateBucket() {

    getArgs "project bucket" "${@}"

    # Get tha APP ID
    gsutil ls -p "${project}" | grep "${bucket}" > /dev/null
    return ${?}
}

### Create bucket if does not exist ###
# usage: createBucket <project> <bucket> <class> [region]
# type: regional or multiregional
function createBucket() {

    getArgs "project bucket class @region" "${@}"

    self validateBucket "${project}" "${bucket}"
    if [ $? -ne 0 ]; then
        gsutil mb -c "${class}" -l "${region}" -p "${project}" gs://"${bucket}"
        exitOnError "Failed to create bucket ${bucket}"
    else
        echo "Bucket '${bucket}' already exist!"
    fi
}

### Create bucket if does not exist ###
# usage: enableVersioning <bucket>
function enableVersioning() {

    getArgs "bucket" "${@}"

    gsutil versioning set on gs://"${bucket}"
    exitOnError "Failed to enable versioning on bucket ${bucket}"
}

### Create bucket if does not exist ###
# usage: setACL <bucket> <ACL>
#  R: READ
#  W: WRITE
#  O: OWNER
function setUserACL() {

    getArgs "bucket user access" "${@}"

    gsutil acl ch -u "${user}":"${access}" gs://"${bucket}"
    exitOnError "Failed to set ACL on bucket ${bucket}"
}
