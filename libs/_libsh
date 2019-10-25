#!/bin/bash
CURRENT_LIB_NAME=$(echo $(cd $(dirname ${BASH_SOURCE[0]}) >/dev/null 2>&1 && pwd) | awk -F / '{print $NF}')
CURRENT_LIB_DIR=$(dirname ${BASH_SOURCE[0]})

# Include main code
source "${CURRENT_LIB_DIR}/main.sh"

# Include the footer
eval "${footLibScript}"
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then 
    getArgs "function &@args" "${@}"
    ${function} "${args[@]}"
fi