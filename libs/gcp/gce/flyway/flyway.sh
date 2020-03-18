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

FLYWAY_HOME=${1:-"/home/flyway"}

if [[ ( -z ${FLYWAY_VM_HOME} ) && ( ! -f ${FLYWAY_HOME}/.profile ) ]]; then
     echo "[ERROR] Unable to locate the required environment variables to proceed."
     exit 1
fi

# Making sure the environment variables are all set, if not, we reload the .profile
[[ ( -z ${FLYWAY_VM_HOME} ) && ( -f ${FLYWAY_HOME}/.profile ) ]] && source ${FLYWAY_HOME}/.profile

source ${FLYWAY_VM_HOME}/scripts/dolibs.sh

# Import required libs
do.import gcp.gce.flyway

verifyDeps flyway
exitOnError "Unable to locate flyway binaries to proceed."

# Performing Flyway info
do.gcp.gce.flyway.info "${FLYWAY_CONF_FILE}" "${FLYWAY_OUTPUT}"

# Performing Flyway migrate
do.gcp.gce.flyway.migrate "${FLYWAY_CONF_FILE}" "${FLYWAY_OUTPUT}"

# Performing Flyway info
do.gcp.gce.flyway.info "${FLYWAY_CONF_FILE}" "${FLYWAY_OUTPUT}"