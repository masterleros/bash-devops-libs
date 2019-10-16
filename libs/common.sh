#!/bin/bash
#echo "Hello from '${BASH_SOURCE[0]}'"
GFT_LIBS_ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd )"

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

# Execute a command until success within a retries
function retryExecution {
    retries=${1}
    shift
    cmd=${@}

    for retry in $(seq $((${retries}+1))); do
        eval "${cmd}"
        if [ ${?} -eq 0 ]; then
            return 0
        elif [ ${retry} -ne $((${retries}+1)) ]; then
            echo "Retying(${retry}) execution of '${cmd}'..."
        fi        
    done

    # if could not be sucess after retries
    exitOnError "The command '${cmd}' could not be executed successfuly after ${retries} retry(s)" -1
}

# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    function=${1}
    shift
    $function "${@}"
fi

# Validate if OS is supported
[[ "${OSTYPE}" == "linux-gnu" ]] || exitOnError "OS '${OSTYPE}' is not supported" -1
