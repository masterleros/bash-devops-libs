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

# Validate required packages
verifyDeps gcloud docker || return ${?}

### Build a docker image and publish to the GCP Container Registry ###
# usage: buildAndPublish <project_id> <docker_dir> <docker_file> <docker_image_name> <docker_build_args>
function buildAndPublish() {

    # Get the arguments
    getArgs "_project_id _docker_dir _docker_file _docker_image_name &@_docker_build_args" "${@}"

    # Create the full image tag
    DOCKER_IMAGE_TAG_LATEST="gcr.io/${_project_id}/${_docker_image_name}:latest"

    # Configure docker to push images into Container Registry
    gcloud --project ${_project_id} --quiet auth configure-docker
    exitOnError "Docker GCP registry could not be configured"

    # Build Image
    docker build -t ${DOCKER_IMAGE_TAG_LATEST} -f ${_docker_file} "${_docker_build_args[@]}" ${_docker_dir}
    exitOnError "It was not possible to build docker image '${DOCKER_IMAGE_TAG_LATEST}'"

    # Publish Image
    docker push ${DOCKER_IMAGE_TAG_LATEST}
    exitOnError "It was not possible to push docker image '${DOCKER_IMAGE_TAG_LATEST}'"

    # Check if custom version can be created based on GIT branch
    DOCKER_IMAGE_VERSION=$(which git &>/dev/null | git rev-parse --abbrev-ref HEAD | sed "s#/\|_\|\.#-#g" | tr '[:upper:]' '[:lower:]')
    if [ "${DOCKER_IMAGE_VERSION}" ]; then

        # Create the full image tag
        DOCKER_IMAGE_TAG_CUSTOM="gcr.io/${_project_id}/${_docker_image_name}:${DOCKER_IMAGE_VERSION}"

        # Tag the custom version
        docker tag ${DOCKER_IMAGE_TAG_LATEST} ${DOCKER_IMAGE_TAG_CUSTOM}
        exitOnError "It was not possible to tag the custom version '${DOCKER_IMAGE_TAG_CUSTOM}'"

        # Publish Image
        docker push ${DOCKER_IMAGE_TAG_CUSTOM}
        exitOnError "It was not possible to push docker image '${DOCKER_IMAGE_TAG_CUSTOM}'"

        # Clean up local custom image
        docker rmi "${DOCKER_IMAGE_TAG_CUSTOM}"
    fi

    # Clean up local image
    docker rmi "${DOCKER_IMAGE_TAG_LATEST}"
}