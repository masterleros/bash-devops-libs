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

# Opt1: Enable dolibs (clone to /tmp)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh #-f /tmp # mode auto

# Opt2: Enable dolibs (clone from ../..)
# source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh -l ../.. # mode local

# Import the required lib
do.import utils

# Optionally you can import all libs from the specified folder at once
# do.recursiveImport ../..

# Use the needed lib
do.utils.showTitle "Hello DevOps Libs!"