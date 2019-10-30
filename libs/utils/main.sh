#!/bin/bash

### Print a nice title ###
# usage: showTitle "title text"
function showTitle {

    getArgs "text" "${@}"

    len=$(echo "# ${text} #"| wc -c)
    separator=$(eval printf '\#%.0s' {2..${len}})
    echoInfo ${separator}
    echoInfo "# ${text} #"
    echoInfo ${separator}
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

        if [ ${?} -eq 0 ]; then
            break
        elif [ ${shownInstruction} -eq 0 ]; then
            echo "${text}"
            shownInstruction=1
        fi
        sleep 5
    done
}
