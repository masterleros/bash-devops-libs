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

### Returns the value requested from the sql database instance. Use assign to get the result ###
# usage: assign var=list <project id> <database instance name> <value>
function getValueFromInstance() {
     getArgs "projectId databaseInstanceName value" "${@}"

     _return=$(gcloud --project ${projectId} sql instances list --filter="NAME=${databaseInstanceName}" --format="value(${value})")
     exitOnError "Unable to retrieve the database '${DATABASE_INSTANCE_NAME}' '${value}'"
}