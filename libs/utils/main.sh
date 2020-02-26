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

### Print a nice title ###
# usage: showTitle "title text"

# @description Print a nice title
# @arg text text Titles's text
function showTitle() {

    getArgs "text" "${@}"
    

    len=$(echo "# ${text} #"| wc -c)
    separator=$(eval printf '\#%.0s' {2.."${len}"})
    echo "        ${separator}"
    echo "        # ${text} #"
    echo "        ${separator}"
}

### Execute a command until success within a retries ###
# usage: retryExecution "command"

# @description Execute a command until success within a retries
# @arg $retries number ammount of retries
# @arg $cmd string command to be executed
function retryExecution() {
    
    getArgs "retries @cmd" "${@}"

    for retry in $(seq $((retries+1))); do
        eval "${cmd}"
        if [ ${?} -eq 0 ]; then
            return 0
        elif [ ${retry} -ne $((retries+1)) ]; then
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
