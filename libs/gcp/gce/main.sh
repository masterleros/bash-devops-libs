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
verifyDeps gcloud || return ${?}

### Returns the zone of a given hostname. Use assign to get the result ###
# usage: assign var=getZoneByHostname <project id> <hostname>
function getZoneByHostname() {
    getArgs "projectId hostname" "${@}"

    _return=$(gcloud --project ${projectId} compute instances list --filter="NAME=${hostname}" --format="value(zone)")
    exitOnError "Failed to retrieve the zone from host '${hostname}'"
}

### Returns the hostname as confirmation if is available. Use assign to get the result ###
# usage: assign var=list <project id> <hostname>
function list() {
     #_return=($(gcloud compute instances list --uri))
     getArgs "projectId hostname" "${@}"

     _return=$(gcloud --project ${projectId} compute instances list --filter="NAME=${hostname}" --format="value(NAME)")
     exitOnError "Failed to list instances"
}

### Configure SSH for the VM ###
# usage: configSSH <project id>
function configSSH() {
     getArgs "projectId" "${@}"

     # Configure SSH
     echoInfo "Configuring SSH..."
     gcloud --project ${projectId} compute config-ssh
     exitOnError
}

### Create a compute instance VM ###
# usage: create <hostname> <&metadataFile> <@parameters>
function create() {
     getArgs "projectId hostname @parameters" "${@}"

     do.utils.showTitle "Creating VM ${hostname}"

     gcloud --project ${projectId} compute instances create ${hostname} ${parameters[*]} | grep -vi password
     exitOnError "Unable to create VM instance ${hostname}"
}

### Delete a compute instance VM ###
# usage: delete <project id> <hostname>
function delete() {
     getArgs "projectId hostname" "${@}"

     assign instance=self list ${projectId} ${hostname}
     assign zone=self getZoneByHostname ${projectId} ${hostname}

     if [[ "${instance}" ]]; then
          gcloud --project ${projectId} compute instances delete ${hostname} --zone ${zone} --quiet
          return $?
     fi
     return 0
}

### Returns the requested metadata from a VM. Use assign to get the result ###
# usage: assign var=getMetadataFromHost <project id> <hostname> <metadata>
function getMetadataFromHost() {
    getArgs "projectId hostname metadata" "${@}"

     assign zone=self getZoneByHostname ${projectId} ${hostname}
    _return=$(gcloud --project ${projectId} compute instances describe ${hostname} --zone ${zone} --format="value(metadata.items[${metadata}])")
}

### Returns the requested metadata from a given file. Use assign to get the result ###
# usage: assign var=getMetadataFromFile <file> <metadata>
function getMetadataFromFile() {
    getArgs "file metadata" "${@}"

    _return=$(cat ${file} | grep -oP "${metadata}=\K[^,]*")
}

### Verifies whether a VM is fully initialized and waits for a time limite in minutes ###
# usage: waitInitialization hostname startupFlag waitMinutesLimit
# where:
# startupFlag is a flag to be monitored in the VM
# waitMinutesLimit is a number in minutes
function waitInitialization() {
     getArgs "projectId hostname startupFlag &waitMinutesLimit" "${@}"

     assign zone=self getZoneByHostname ${projectId} ${hostname}
     assign statusFlag=self getMetadataFromHost ${projectId} ${hostname} ${startupFlag}

     [ "${waitMinutesLimit}" ] || waitMinutesLimit=10
     [ ${waitMinutesLimit} -gt 1 ] && calculation=" / 60" || calculation=
     expirationEpochDateTime=$(($(date -u +"%s") + ${waitMinutesLimit} * 60))

     echoInfo "Checking whether the ${hostname} VM is fully initialized. Time expiration limit is ${waitMinutesLimit} min"

     while [ ${statusFlag} == "unknown" ]
     do
          [ $(($((expirationEpochDateTime - $(date -u +"%s")))${calculation} )) -le 0 ] && exitOnError "${hostname} startup time limit has expired." 1

          assign statusFlag=self getMetadataFromHost ${projectId} ${hostname} ${startupFlag}
          [ ${statusFlag} == "error" ] && exitOnError "${hostname} startup has finished with error and cannot be used." 1
          sleep 5
     done

     echoInfo "${hostname} VM is fully initialized."
}