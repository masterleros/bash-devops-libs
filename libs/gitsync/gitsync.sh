#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../common.sh



###############################################################################
# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    getArgs "function &@args" ${@}
    ${function} "${args[@]}"
fi
###############################################################################