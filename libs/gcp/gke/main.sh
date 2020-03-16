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
checkBins gcloud || return ${?}

### Set the requested project and then get credentials for the cluster ###
# usage: loginCluster <cluster_name> <zone> <gcp_project_id>
function loginCluster() {
    getArgs "cluster_name zone project"
 
    # Gets credentials to use the cluster
    gcloud --quiet --project="${project}" container clusters get-credentials "${cluster_name}" --zone="${zone}"
    exitOnError "It is not possible to authenticate to the cluster"
}

### Describe cluster ###
# usage describeCluster <cluster_name> <zone>
function describeCluster() {
    getArgs "cluster_name zone project"

    # Describe cluster
    gcloud --quiet --project="${project}" container clusters describe "${cluster_name}" --zone="${zone}"
    exitOnError "It is not possible to show the description for cluster ${cluster_name}, it may not exist"
}
