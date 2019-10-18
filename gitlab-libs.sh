#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/libs/common.sh

getArgs "PROJECT_FOLDER" ${@}

# Check if folder exists
test -d ${PROJECT_FOLDER}
exitOnError "${PROJECT_FOLDER} folder does not exist!"

# Create folder and install libs to project
mkdir -p ${PROJECT_LIB_FOLDER}/scripts
cp -R ${GITLAB_LIBS_ROOTDIR}/libs ${PROJECT_FOLDER}

