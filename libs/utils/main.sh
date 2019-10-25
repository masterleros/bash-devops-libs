#!/bin/bash
eval "${headLibScript}"

### Print a nice title ###
# usage: showTitle "title text"
function showTitle {

    getArgs "text" "${@}"

    len=$(echo "# ${text} #"| wc -c)
    separator=$(eval printf '\#%.0s' {2..$len})
    echoInfo $separator
    echoInfo "# ${text} #"
    echoInfo $separator
}

### This function will echo the content of a file with tokens updated to values ###
# usage: tokenReplaceFromFile <path_to_file> [continue<true>]
function tokenReplaceFromFile {

    getArgs "file &continue" "${@}"
    
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
            echoError "Variable '${var}' is not defined!"
            ((retval+=1))
        fi
    done

    # If is not set to continue
    if [[ "${continue}" != "true" ]]; then
        exitOnError "Some tokens could not be replaced" ${retval} 
    fi

    echo "${content}"
}

### This function will replace from a file to file
# usage: tokenReplaceInFile <path_source> [path_target]
function tokenReplaceInFile {

    getArgs "path_source @path_target" "${@}"

    # If not specified file, use source as target
    if [ ! "${path_target}" ]; then path_target=${path_source}; fi

    # Replace tokens, if not present, fail
    utilslib.tokenReplaceFromFile ${path_source} > ${path_target}
}

### Execute a command until success within a retries ###
# usage: retryExecution "command"
function retryExecution {
    
    getArgs "retries @cmd" "${@}"

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

### Wait with a message until a condition is true ###
# usage: showTextUntil <cmd> <text>
function showTextUntil {
    
    getArgs "cmd text" "${@}"

    # Wait until firebase project is available
    shownInstruction=0
    while [ True ]; do

        # execute the verification command
        eval "${cmd}"

        if [ $? -eq 0 ]; then
            break
        elif [ ${shownInstruction} -eq 0 ]; then
            echo "${text}"
            shownInstruction=1
        fi
        sleep 5
    done
}

# Export internal functions
eval "${footLibScript}"