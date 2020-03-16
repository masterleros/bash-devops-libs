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

# Import required libs
do.import gcp.gce utils utils.tokens utils.configs

FLYWAY_VM_METADATA_TEMPLATE="${ROOTDIR}/scripts/devops-libs/gcp/gce/flyway/flyway-vm-metadata.template"
FLYWAY_SCRIPT="${ROOTDIR}/scripts/devops-libs/gcp/gce/flyway/flyway.sh"
STARTUP_FLAG="FINISHED_STARTUP_FLAG"
VM_USERID="ubuntu"

### Execute the flyway actions. This is an private function ###
# usage: _execute <action> <configFile> <outputFile>
function _execute() {
     getArgs "action configFile output" "${@}"

     do.utils.showTitle "Performing flyway ${action}"
     flyway -configFiles=${configFile} ${action} | tee ${output}
     return $?
}

### Execute the flyway info action. ###
# usage: info <configFile> <outputFile>
function info() {
     getArgs "configFile output" "${@}"
     self _execute "info" ${@}
     exitOnError "Flyway failed to perform info action"

     [ ! -f ${output} ] && exitOnError "Unable to proceed without file ${output}"
     cat ${output} | grep -i "empty" > /dev/null
     if [[ $? -eq 0 ]]; then
          do.utils.showTitle "Flyway schema is not present. Setting current version as baseline"
          self baseline ${@}

          self info ${@}
          exitOnError "Flyway failed to perform info action"
     fi
}

### Execute the flyway baseline action. ###
# usage: baseline
function baseline() {
     self _execute "baseline" ${@}
     exitOnError "Flyway failed to perform baseline action"
}

### Execute the flyway migrate action. ###
# usage: migrate
function migrate() {
     self _execute "migrate" ${@}
     exitOnError "Flyway failed to perform migrate action"
}

### Deletes the Flyway VM. ###
# usage: deleteVM <projectId>
function deleteVM() {
     getArgs "projectId" "${@}"

     assign hostname=self getVMName

     echoInfo "Deleting ${hostname} VM"
     do.gcp.gce.delete ${projectId} ${hostname}
}

### Creates the Flyway VM. ###
# usage: createVM <projectId> <@parameters>
function createVM() {
     getArgs "projectId @parameters" "${@}"

     assign hostname=self getVMName

     do.utils.tokens.replaceFromFileToFile ${FLYWAY_VM_METADATA_TEMPLATE} ${FLYWAY_VM_METADATA_TEMPLATE}
     exitOnError "Fail to replace variables in '${FLYWAY_VM_METADATA_TEMPLATE}'"

     assign FLYWAY_VM_METADATA=do.utils.configs.getAllArgsFromFile ${FLYWAY_VM_METADATA_TEMPLATE}

     # Creating the Flyway VM
     do.gcp.gce.create ${projectId} ${hostname} ${parameters[@]} ${FLYWAY_VM_METADATA[@]}

     # Wait 20s to SSH to be UP
     sleep 20

     # Configure SSH
     do.gcp.gce.configSSH ${projectId}
}

### Verifies whether the Flyway VM is fully initialized and waits for a time limite in minutes ###
# usage: waitInitialization <projectId>
function waitInitialization() {
     getArgs "projectId" "${@}"

     assign hostname=self getVMName

     # Verifies and wait for the VM initialization. Expiration wait limit is 10 min
     do.gcp.gce.waitInitialization ${projectId} ${hostname} ${STARTUP_FLAG}
}

### Returns the VM name. Use the assign function to get the return ###
# usage: assign var=getVMName
function getVMName() {
     assign FLYWAY_VM_HOSTNAME=do.gcp.gce.getMetadataFromFile ${FLYWAY_VM_METADATA_TEMPLATE} FLYWAY_VM_HOSTNAME
     _return=${FLYWAY_VM_HOSTNAME}
}

### Returns the VM home. Use the assign function to get the return ###
# usage: assign var=getVMHome
function getVMHome() {
     assign FLYWAY_VM_HOME=do.gcp.gce.getMetadataFromFile ${FLYWAY_VM_METADATA_TEMPLATE} FLYWAY_VM_HOME
     _return=${FLYWAY_VM_HOME}
}

### Copies all required files to the target VM. ###
# usage: copyFilesToVM <projectId> <@folders>
function copyFilesToVM() {
     getArgs "projectId @folders" "${@}"

     assign hostname=self getVMName
     assign zone=do.gcp.gce.getZoneByHostname ${projectId} ${hostname}
     assign home=self getVMHome
     destination="${VM_USERID}@${hostname}"

     # Copying the required files into the new VM
     echoInfo "Copying required files to ${destination}:${home}"
     gcloud --project ${projectId} compute scp --compress --recurse --zone ${zone} ${folders[*]} ${destination}:${home}

     [ -f ${FLYWAY_SCRIPT} ] || exitOnError "Unable to find '${FLYWAY_SCRIPT}' to proceed." -1

     # Copying flyway script
     gcloud --project ${projectId} compute scp --compress --recurse --zone ${zone} ${FLYWAY_SCRIPT} ${destination}:${home}/flywaydb
}

### Runs the flyway script in the target VM. ###
# usage: runFlywayRemote <projectId>
function runFlywayRemote() {
     getArgs "projectId" "${@}"

     assign hostname=self getVMName
     assign home=self getVMHome
     assign zone=do.gcp.gce.getZoneByHostname ${projectId} ${hostname}

     # Creating the VM Domain Name
     fqdn="${hostname}.${zone}.${projectId}"

     ssh -o StrictHostKeyChecking=no -t ${VM_USERID}@${fqdn} "
find ${home} -type f -iname \"*.sh\" -exec chmod +x {} \;
if [[ ! -f ${home}/flywaydb/flyway.sh ]]; then
     echo [ERROR] Unable to find ${home}/flywaydb/flyway.sh to proceed.
     return -1
fi
${home}/flywaydb/./flyway.sh ${home}
"
exitOnError
}
