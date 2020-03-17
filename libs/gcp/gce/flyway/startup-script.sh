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

ZONE=$(gcloud compute instances list --filter="NAME=${HOSTNAME}" --format="value(zone)")
INSTALLATION_BIN="https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/6.2.1/flyway-commandline-6.2.1-linux-x64.tar.gz"
STARTUP_FLAG="FINISHED_STARTUP_FLAG"
VM_USERID="ubuntu"
USER_HOME="/home/${VM_USERID}"

function updateMetadataStatus {
    STATUS=$1

    echo "INFO:   Updating VM status to ${STATUS}"
    gcloud compute instances add-metadata ${HOSTNAME} --zone=${ZONE} --metadata=${STARTUP_FLAG}="${STATUS}"
}

function startSuccess() {
    updateMetadataStatus "success"
}

function startError() {
    updateMetadataStatus "error"
}

sudo apt-get update
export FLYWAY_VM_HOSTNAME=flyway-vm
export FLYWAY_VM_HOME=${USER_HOME}
export FLYWAY_PATH=${USER_HOME}/flywaydb
export FLYWAY_CONF_FILE=${FLYWAY_PATH}/flyway.conf
export FLYWAY_SQL_REMOTE_FOLDER=${USER_HOME}/sql
export FLYWAY_OUTPUT=${USER_HOME}/sql/flyway.out

echo "INFO:   Installing Flyway binaries from ${INSTALLATION_BIN} ..."

mkdir -p ${FLYWAY_VM_HOME}
mkdir -p ${FLYWAY_VM_HOME}/bin
cd ${FLYWAY_VM_HOME}

wget -qO- ${INSTALLATION_BIN} | tar xvz && mv flyway-6.2.1 $(basename ${FLYWAY_PATH})
if [[ $? -ne 0 ]]; then
    echo "ERROR:   An error occurred when downloading and installing Flyway. Please, try again."
    startError
fi

CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt ${CLOUD_SDK_REPO} main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Update sources
sudo apt-get update

# Install dependencies
sudo apt-get install -y google-cloud-sdk

if [[ -f ${FLYWAY_PATH}/flyway ]]; then
    chmod +x ${FLYWAY_PATH}/flyway

    cd ${FLYWAY_VM_HOME}/bin;ln -s ${FLYWAY_PATH}/flyway flyway

    sudo chown -R ${VM_USERID}:${VM_USERID} ${FLYWAY_VM_HOME}
    echo "INFO:   Flyway binaries have been installed successfully"

    cat << EOF >> ${FLYWAY_VM_HOME}/.profile

export FLYWAY_VM_HOME=${FLYWAY_VM_HOME}
export FLYWAY_PATH=${FLYWAY_PATH}
export FLYWAY_CONF_FILE=${FLYWAY_CONF_FILE}
export FLYWAY_SQL_REMOTE_FOLDER=${FLYWAY_SQL_REMOTE_FOLDER}
export FLYWAY_OUTPUT=${FLYWAY_OUTPUT}
EOF

    startSuccess
else
    echo "ERROR:   Unable to locate Flyway binary at '${FLYWAY_PATH}/flyway'"
    startError
fi