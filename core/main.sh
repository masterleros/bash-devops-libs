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

#!/bin/bash
echoInfo "Loading dolibs..."

# Verify bash version
awk 'BEGIN { exit ARGV[1] < 4.3 }' "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
exitOnError "Bash version needs to be '4.3' or newer (current: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})"

# Check if not being included twice
[ ! "${DOLIBS_LOADED}" ] || exitOnError "You cannot include twice the core library"

# Include core
. "${DOLIBS_CORE_DIR}/core.sh"

# Import modules
for DOLIBS_MODULE in $(ls "${DOLIBS_CORE_DIR}/"mod-*.*); do
    # echoInfo "Loading '${DOLIBS_MODULE}' module..."
    dolibImportModule "${DOLIBS_MODULE}"
done

# Export all values required for sub-processes
# be able to use the core lib
export DOLIBS_LOADED=true
export DOLIBS_MODE=${DOLIBS_MODE}
export DOLIBS_REPO=${DOLIBS_REPO}
export DOLIBS_BRANCH=${DOLIBS_BRANCH}
export DOLIBS_DIR=${DOLIBS_DIR}
export DOLIBS_ROOTDIR=${DOLIBS_ROOTDIR}
export DOLIBS_TMPDIR=${DOLIBS_TMPDIR}
export DOLIBS_LIBS_DIR=${DOLIBS_DIR}/libs
export DOLIBS_SOURCE_LIBS_DIR=${DOLIBS_SOURCE_DIR}/libs

# Import main do functions (to manage libs)
dolibUpdate "do" "${DOLIBS_SOURCE_LIBS_DIR}/do" "${DOLIBS_LIBS_DIR}" "do"
dolibCreateLibFunctions "do" "${DOLIBS_LIBS_DIR}/do"