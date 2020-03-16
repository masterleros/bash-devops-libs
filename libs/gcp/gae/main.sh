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

# Import dependencies
do.import utils.tokens

### Function to wait any in-course operation. Use assign to get the return ###
# usage: assign var=operationInCourse <projectId> <version>
function operationInCourse() {
    getArgs "projectId service version" "${@}"

    # Wait if there is a running operations for the service
    _return=$(gcloud --project ${projectId} app operations list --filter="op_resource.metadata.target:/${service}/versions/${version} AND NOT op_resource.done=true" --format="value(ID)")
}

### Function to wait any in-course operation ###
# usage: waitOperation <projectId> <service> <version>
function waitOperation() {

    getArgs "projectId service version" "${@}"

    # Wait if there is a running operations for the service
    assign operation=self operationInCourse "${projectId}" "${service}" "${version}"
    [ "${operation}" ] && gcloud app operations wait "${operation}"
}

### Identifies the version ids of a given service that are statuses STOPPED and purge them. ###
# usage: purgeStoppedVersions <projectId> <&service>
function purgeStoppedVersions() {
    getArgs "projectId &service" "${@}"

    [ "${service}" ] || service="default"

    versionIds=($(gcloud --project ${projectId} app versions list --filter="SERVING_STATUS=STOPPED AND SERVICE=${service}" --format="value(VERSION.ID)"))

    for versionId in "${versionIds[@]}"
    do
        assign operation=self operationInCourse "${projectId}" "${service}" "${versionId}"
        [ "${operation}" ] && continue

        gcloud --project ${projectId} --quiet app versions delete --service="${service}" "${versionId}"
        exitOnError
    done
}

### Identifies all versions that have traffic split equal to zero and stops them. ###
# usage: stopOldVersions <projectId> <numberVersionsToKeep> <&service>
function stopOldVersions() {
    getArgs "projectId numberVersionsToKeep &service" "${@}"

    [ "${service}" ] || service="default"
    versionIds=($(gcloud --project keane-docc-dev app versions list --filter="TRAFFIC_SPLIT=0 AND SERVICE=${service}" --sort-by="~LAST_DEPLOYED" --format="value(VERSION.ID)"))

    # If number of versions is greater than the number that we should keep, we continue, else we exit from here
    [ ${#versionIds[@]} -gt ${numberVersionsToKeep} ] || return 0

    gcloud --project ${projectId} --quiet app versions stop --service="${service}" "${versionIds[@]:${numberVersionsToKeep}}"

}

### Identifies all versions that have traffic split equal to zero, stops and purge them, keeping the older versions according to the number of versions to keep. ###
# usage: stopOldVersionsAndPurge <projectId> <numberVersionsToKeep> <&service>
function stopOldVersionsAndPurge() {
    getArgs "projectId numberVersionsToKeep &service" "${@}"

    self stopOldVersions ${projectId} ${numberVersionsToKeep} ${service}
    self purgeStoppedVersions ${projectId} ${service}
}

### Function to deploy a gae app ###
# usage: deploy <projectId> <path> [version]
function deploy {

    getArgs "projectId path &version" "${@}"

    # Detokenize the file
    echoInfo "Creating detokenized yaml..."
    local detokenizedFile="$(dirname ${path})/detokenized_$(basename ${path})"
    do.utils.tokens.replaceFromFileToFile ${path} ${detokenizedFile} true
    exitOnError "It was not possible to replace all the tokens in '${path}', please check if values were exported."

    # Get service name
    service=$(cat ${detokenizedFile} | grep -e ^service: | awk '{print $NF}')
    [ ${service} ] || service="default"

    # If it is requesting a specific version
    [ "${version}" ] && parameters=" --version ${version}" || parameters=

    gcloud --project ${projectId} --quiet app deploy ${detokenizedFile}${parameters}
    exitOnError "Failed to deploy the application"

    # Remove tokenized yamls
    echoInfo "Removing detokenized yaml..."
    rm ${detokenizedFile}
}
