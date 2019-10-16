#!/bin/bash

### Exit program with text when last exit code is non-zero ###
# usage: exitOnError <output_message> [optional: forced code (defaul:exit code)]
###########################################
function exitOnError {
    text=$1
    code=${2:-$?}
    if [ "${code}" -ne 0 ]; then
        if [ ! -z "${text}" ]; then echo -e "ERROR: ${text}" >&2 ; fi
        echo "Exiting..." >&2
        exit $code
    fi
}

