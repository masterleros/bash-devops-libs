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

# Include the header
CURRENT_LIB=${1}
CURRENT_LIB_DIR=${2}
CURRENT_LIB_ENTRYPOINT=${3}

# Include main code
. "${CURRENT_LIB_ENTRYPOINT}" || return ${?}

# Include the footer (deprecated)
# if [ $(basename ${0}) == $(basename ${BASH_SOURCE[0]}) ]; then 
#     getArgs "function &@args" "${@}"
#     ${function} "${args[@]}"
# fi
