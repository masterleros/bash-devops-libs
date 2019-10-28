#!/bin/bash
CURRENT_LIB=${1}
CURRENT_LIB_PATH=${2}

# Include main code
source ${CURRENT_LIB_PATH}/${DEVOPS_LIBS_MAIN_FILE} || return ${?}

# # Include the footer
if [ $(basename ${0}) == $(basename ${BASH_SOURCE[0]}) ]; then 
    getArgs "function &@args" "${@}"
    ${function} "${args[@]}"
fi