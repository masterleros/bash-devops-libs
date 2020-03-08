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

# @file global
# @brief This lib will source your script defined in 'DOLIBS_GLOBALS_PATH' variable, if not defined, the default value is `globals.sh` file placed in the `dolibs.sh` folder.
# @brief 
# @brief Doin so, will enable the lib to use centralized values defined for your scripts.

[ "${DOLIBS_GLOBALS_PATH}" ] || DOLIBS_GLOBALS_PATH=${DOLIBS_ROOTDIR}/globals.sh

# Check if file exists
if [ -f "${DOLIBS_GLOBALS_PATH}" ]; then
    source "${DOLIBS_GLOBALS_PATH}"
    echoInfo "Global definition file is included now!"
else
    exitOnError "Global defintion file '${DOLIBS_GLOBALS_PATH}' was not found"
fi
