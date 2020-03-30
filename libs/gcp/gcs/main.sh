#!/bin/bash
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


# Verify Dependencies
checkBins gsutil

# @description Check if a bucket exist
# @arg $project id of the GCP project
# @arg $bucket name of the bucket to check
# @return 0 if bucket exist
# @example
#   validateBucket <project> <bucket>
function validateBucket() {

    getArgs "project bucket"

    # Get tha APP ID
    gsutil ls -p "${project}" | grep "${bucket}" > /dev/null
    return ${?}
}



# @description Create a bucket if it does not exist
# @arg $project id of the GCP project
# @arg $bucket name of the bucket to create
# @arg $class 'regional' or 'multiregional'
# @arg [$region] optional region
# @exitcode 0 Bucket created
# @exitcode non-0 Bucket not created due to error
# @example
#   createBucket <project> <bucket> <class> [region]
function createBucket() {

    getArgs "project bucket class @region"

    self validateBucket "${project}" "${bucket}"
    if [ $? -ne 0 ]; then
        gsutil mb -c "${class}" -l "${region}" -p "${project}" gs://"${bucket}"
        exitOnError "Failed to create bucket ${bucket}"
    else
        echo "Bucket '${bucket}' already exist!"
    fi
}



# @description Enable versioning into a bucket
# @arg $bucket name of the bucket to enable versioning
# @exitcode 0 Bucket versioning enabled
# @exitcode non-0 Bucket versioning not enabled
# @example
#   enableVersioning <bucket>
function enableVersioning() {

    getArgs "bucket"

    gsutil versioning set on gs://"${bucket}"
    exitOnError "Failed to enable versioning on bucket ${bucket}"
}


# @description Enable versioning into a bucket
# @arg $bucket name of the bucket to enable versioning
# @arg $user
# @arg $ACL one of:
#     R: READ
#     W: WRITE
#     O: OWNER
# @exitcode 0 Bucket ACL set
# @exitcode non-0 Bucket ACL not set
# @example
#   setACL <bucket> <user> <ACL>
function setUserACL() {

    getArgs "bucket user access"

    gsutil acl ch -u "${user}":"${access}" gs://"${bucket}"
    exitOnError "Failed to set ACL on bucket ${bucket}"
}
