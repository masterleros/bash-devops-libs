#!/bin/bash

### Exit program when error with output ###
# usage: exitOnError <output_message> [optional: code (defaul:exit code)]
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