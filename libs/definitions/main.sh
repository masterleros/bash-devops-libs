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

# @file definitions
# @brief This lib will include your `definitions.sh` file placed in the `dolibs.sh` folder by doing a ```source <path>/definition.sh```. 
# @brief 
# @brief Doin so, will enable the lib to use centralized values defined for your scripts.

export DOLIBS_DEFINITIONS=${DOLIBS_ROOTDIR}/definitions.sh

# Check if file exists
if [ -f "${DOLIBS_DEFINITIONS}" ]; then
    source "${DOLIBS_DEFINITIONS}"
    echoInfo "Definitions file is included now!"
else
    exitOnError "Defintions file '${DOLIBS_DEFINITIONS}' was not found"
fi
