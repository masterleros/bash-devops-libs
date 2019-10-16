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

### Validate declarations ###
function validateVars {
    retval=0
    for var in $@; do       
        if [ -z "${!var}" ]; then
            echo "Environment varirable '${var}' is not declared!"
            ((retval+=1))
        fi    
    done
    exitOnError "Some variables were not found" ${retval}
}

### dependencies verification ###
function verifyDeps {
    retval=0
    for dep in $@; do
        which ${dep} &> /dev/null
        if [[ $? -ne 0 ]]; then
            echo "Binary dependency '${dep}' not found!"
            ((retval+=1))
        fi
    done
    exitOnError "Some dependencies were not found" ${retval}
}

### This funciton will map environment          ###
### variables to the final name                 ###
### Example: [ENV]_CI_[VAR_NAME] -> [VAR NAME]  ###
function printEnvMappedVarsExports {

    branch=${CI_COMMIT_REF_NAME}
    exports=""    

    # Environment regarding branch    
    if [[ "${branch}" == "feature/"* ]] || [[ "${branch}" == "fix/"* ]]; then env="DEV";
    elif [[ "${branch}" == "develop" ]]; then env="INT"; 
    elif [[ "${branch}" == "release/"* ]] || [[ "${branch}" == "bugfix/"* ]]; then env="UAT";
    elif [[ "${branch}" == "master" ]] || [[ "${branch}" == "hotfix/"* ]]; then env="PRD";
    else
        echo "'${branch}' branch naming is not supported!" >&2
        exit -1
    fi

    # Get vars to be renamed    
    vars=($(printenv | egrep -o "${env}_CI_.*" | awk -F= '{print $1}'))
    echo "Found vars (${env}):"
    echo "${vars}"

    # Set same variable with the final name
    for var in "${vars[@]}"; do
        var=$(echo ${var} | awk -F '=' '{print $1}')
        new_var=$(echo ${var} | cut -d'_' -f3-)
        exports="export $new_var=\${$var};${exports}"
    done

    # print the exports required
    echo $exports
}

# Validate if OS is supported
[[ "${OSTYPE}" == "linux-gnu" ]] || exitOnError "OS '${OSTYPE}' is not supported" -1

# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    function=${1}
    shift
    $function "${@}"
fi    