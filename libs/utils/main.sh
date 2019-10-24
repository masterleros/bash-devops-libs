#!/bin/bash
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
[ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ] && source ${CURRENT_DIR}/../libs/base.sh

### Print a nice title ###
# usage: showTitle "title text"
function showTitle {

    getArgs "text" ${@}

    len=$(echo "# ${text} #"| wc -c)
    separator=$(eval printf '\#%.0s' {2..$len})
    echo $separator
    echo "# ${text} #"
    echo $separator
}

### This function will echo the content of a file with tokens updated to values ###
# usage: tokenReplaceFromFile <path_to_file> [continue<true>]
function tokenReplaceFromFile {

    getArgs "file &continue" ${@}
    
    # Check if file exists
    [ -f ${file} ] || exitOnError "File '${file}' not found"
    content=$(cat ${file})

    # Get tokens
    tokens=($(echo ${content} | egrep -o '\$\{([a-zA-Z0-9_]+)\}'))

    # Replace each var if exists
    retval=0
    for token in ${tokens[@]}; do
        # If variable is defined, replace
        var=$(echo ${token} | egrep -o '([a-zA-Z0-9_]+)')
        if [ "${!var}" ]; then
            content=${content//$token/${!var}}
        else
            echo "Variable '${var}' is not defined!" >&2
            ((retval+=1))
        fi
    done

    # If is not set to continue
    if [[ "${continue}" != "true" ]]; then
        exitOnError "Some tokens could not be replaced" ${retval} 
    fi

    echo "${content}"
}

### Execute a command until success within a retries ###
# usage: retryExecution "command"
function retryExecution {
    
    getArgs "retries @cmd" ${@}

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