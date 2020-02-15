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

# Enable dolibs (clone to /tmp)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh -f /tmp -l ../..

# Set the custom lib source
do.addGitSource myremotelib "masterleros/bash-devops-libs" feature/cleanup

# Import the required lib from custom namespace
do.import myremotelib.utils

# Use the needed lib
do.myremotelib.utils.showTitle "Hello DevOps Libs!"