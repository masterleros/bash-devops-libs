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


# Validate required packages
checkBins gcloud docker || return ${?}

# Define the GCloud registry host
export GCLOUD_DOCKER_REGISTRY_HOST="us.gcr.io"
export DOCKER_CONFIG_DIR="${HOME}/.docker"
export DOCKER_CONFIG_PATH="${DOCKER_CONFIG_DIR}/docker.json"
export DOCKER_LOCKFILE_PATH="${DOCKER_CONFIG_DIR}/.${GCLOUD_DOCKER_REGISTRY_HOST}.lock"
export DOCKER_LOCKFILE_DESC=100

# @description Login with current GOOGLE_APPLICATION_CREDENTIALS to GCloud registry
# @exitcode 0 Logged in successfuly
# @exitcode non-0 Logged in failed
# @example
#   dockerLogin()
function dockerLogin() {

    do.import gcp.auth

    # Check if credential definition is present
    checkVars GOOGLE_APPLICATION_CREDENTIALS
    exitOnError "Required credentials not found"

    # Get credential user
    assign _saUser=gcp.auth.getValueFromCredential "${GOOGLE_APPLICATION_CREDENTIALS}" client_email
    exitOnError "It was not possible to get the credential user email"

    # Create docker config folder if does not exist
    DOCKER_LOCKFILE_DIR=$(dirname "${DOCKER_LOCKFILE_PATH}")
    [ -d "${DOCKER_LOCKFILE_DIR}" ] || mkdir -p "${DOCKER_LOCKFILE_DIR}"

    # Create the lock descriptor    
    #exec "{DOCKER_LOCKFILE_DESC}">"${DOCKER_LOCKFILE_PATH}"
    #exitOnError "It was not possible to aquire the lock"    
    # Aquire the soft lock for this process
    flock -s ${DOCKER_LOCKFILE_DESC}

    # Check if is not logged as required user
    _loggedUser=$(< "${DOCKER_LOCKFILE_PATH}" egrep "^gcr_sa=" | cut -d'=' -f2-)
    [ ! "${_loggedUser}" ] || [ "${_loggedUser}" != "${_saUser}" ]
    exitOnError "'${_loggedUser}' is currently using docker ${GCLOUD_DOCKER_REGISTRY_HOST} registry"

    # Docker login to GCloud registry
    echoInfo "Docker loging-in to 'https://${GCLOUD_DOCKER_REGISTRY_HOST}'..."
    < "${GOOGLE_APPLICATION_CREDENTIALS}" docker login -u _json_key --password-stdin https://"${GCLOUD_DOCKER_REGISTRY_HOST}"
}

# @description Logoff of current GCloud registry
# @example
#   dockerLogoff()
function dockerLogoff() {

    # Check if the lock is in place yet
    flock -n "${DOCKER_LOCKFILE_DESC}"

    # If the locked by other, do not logoff
    if [ ${?} -eq 0 ]; then
        echoInfo "Docker loging-out from 'https://${GCLOUD_DOCKER_REGISTRY_HOST}'..."
        docker logout https://"${GCLOUD_DOCKER_REGISTRY_HOST}"
        rm "${DOCKER_LOCKFILE_PATH}"
    fi

    # Remove soft lock of this proccess
    flock -s -u ${DOCKER_LOCKFILE_DESC}
}

# @description Get the digest of a specific tagged image
# @arg $project_id id of the GCP project
# @arg $docker_image_name name of the docker image
# @arg $docker_image_tag tag of the docker image
# @return digest of an image
# @example
#   getImageDigest <project_id> <docker_image_name> <docker_image_tag>
function getImageDigest() {
    # Get the arguments
    getArgs "_project_id _docker_image_name _docker_image_tag"

    # Create the image tag and retrieve the digest
    DOCKER_IMAGE="${GCLOUD_DOCKER_REGISTRY_HOST}/${_project_id}/${_docker_image_name}"
    _return=$(gcloud container images list-tags "${DOCKER_IMAGE}" --filter="TAGS=${_docker_image_tag}" --format="get(digest)")
    _result=${?}

    return ${_result}
}

# @description Get the full digest path (with registry/project/image/digest) of a specific tagged image
# @arg $project_id id of the GCP project
# @arg $docker_image_name name of the docker image
# @arg $docker_image_tag tag of the docker image
# @return digest of an image
# @example
#   getFullDigestTag <project_id> <docker_image_name> <docker_image_tag>
function getFullDigestTag() {
    # Get the arguments
    getArgs "_project_id _docker_image_name _docker_image_tag"

    # Get the image tag digest
    assign _tagDigest=self getImageDigest "${_project_id}" "${_docker_image_name}" "${_docker_image_tag}"
    _result=${?}

    # Return the full image digest tag
    _return="${GCLOUD_DOCKER_REGISTRY_HOST}/${_project_id}/${_docker_image_name}@${_tagDigest}"
    return ${_result}
}

# @description Build a docker image and publish to the GCP Container Registry
# @arg $project_id id of the GCP project
# @arg $docker_dir path to a directory containing an docker file
# @arg $docker_file filename of the docker to be build
# @arg $docker_image_name name of the resulting docker image
# @arg @$docker_builder_args optional rest arguments for docker builder args
# @return digest of an image
# @example
#   buildAndPublish <project_id> <docker_dir> <docker_file> <docker_image_name> <docker_build_args>
function buildAndPublish() {

    # Get the arguments
    getArgs "_project_id _docker_dir _docker_file _docker_image_name @_docker_build_args="

    # Create the full image tag
    DOCKER_IMAGE_TAG_LATEST="${GCLOUD_DOCKER_REGISTRY_HOST}/${_project_id}/${_docker_image_name}:latest"

    # Login to GCR
    self dockerLogin

    # Build Image
    docker build -t "${DOCKER_IMAGE_TAG_LATEST}" -f "${_docker_file}" "${_docker_build_args[@]}" "${_docker_dir}"
    exitOnError "It was not possible to build docker image '${DOCKER_IMAGE_TAG_LATEST}'"

    # Publish Image
    docker push "${DOCKER_IMAGE_TAG_LATEST}"
    exitOnError "It was not possible to push docker image '${DOCKER_IMAGE_TAG_LATEST}'"

    # Check if custom version can be created based on GIT branch
    DOCKER_IMAGE_VERSION=$(which git &>/dev/null | git rev-parse --abbrev-ref HEAD | sed "s#/\|_\|\.#-#g" | tr '[:upper:]' '[:lower:]')
    if [ "${DOCKER_IMAGE_VERSION}" ]; then

        # Create the full image tag
        DOCKER_IMAGE_TAG_CUSTOM="${GCLOUD_DOCKER_REGISTRY_HOST}/${_project_id}/${_docker_image_name}:${DOCKER_IMAGE_VERSION}"

        # Tag the custom version
        docker tag "${DOCKER_IMAGE_TAG_LATEST}" "${DOCKER_IMAGE_TAG_CUSTOM}"
        exitOnError "It was not possible to tag the custom version '${DOCKER_IMAGE_TAG_CUSTOM}'"

        # Publish Image
        docker push "${DOCKER_IMAGE_TAG_CUSTOM}"
        exitOnError "It was not possible to push docker image '${DOCKER_IMAGE_TAG_CUSTOM}'"

        # Clean up local custom image
        docker rmi "${DOCKER_IMAGE_TAG_CUSTOM}"
    fi

    # Docker Logoff from GCloud registry
    self dockerLogoff

    # Clean up local image
    docker rmi "${DOCKER_IMAGE_TAG_LATEST}"
}
