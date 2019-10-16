#!/bin/bash
GFT_LIBS_ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd )"

### Exit program with text when last exit code is non-zero ###
# usage: exitOnError <output_message> [optional: forced code (defaul:exit code)]
function exitOnError {
    text=${1}
    code=${2:-$?}
    if [ "${code}" -ne 0 ]; then
        if [ ! -z "${text}" ]; then echo -e "ERROR: ${text}" >&2 ; fi
        echo "Exiting..." >&2
        exit $code
    fi
}

### get arguments ###
# usage: getArgs "<arg_name1> <arg_name2> ... <arg_nameN>" ${@}
function getArgs {
    retval=0
    args=(${1})
    for arg in ${args[@]}; do
        shift
        if [ ! "${1}" ]; then
            echo "Argument '${arg}' not found!" >&2
            ((retval+=1))
        else
            eval "${arg}='${1}'"
        fi        
    done
    exitOnError "Some arguments are missing" ${retval}
}

### Validate defined variables ###
# usage: validateVars <var1> <var2> ... <varN>
function validateVars {
    retval=0
    for var in ${@}; do       
        if [ -z "${!var}" ]; then
            echo "Environment varirable '${var}' is not declared!" >&2
            ((retval+=1))
        fi    
    done
    exitOnError "Some variables were not found" ${retval}
}

### dependencies verification ###
# usage: verifyDeps <dep1> <dep2> ... <depN>
function verifyDeps {
    retval=0
    for dep in ${@}; do
        which ${dep} &> /dev/null
        if [[ $? -ne 0 ]]; then
            echo "Binary dependency '${dep}' not found!" >&2
            ((retval+=1))
        fi
    done
    exitOnError "Some dependencies were not found" ${retval}
}

### This funciton will map environment variables to the final name ###
# Usage: printEnvMappedVarsExports
# Example: [ENV]_CI_[VAR_NAME] -> [VAR NAME]  ### 
function printEnvMappedVarsExports {

    validateVars ${CI_COMMIT_REF_NAME}    

    # Environment regarding branch    
    if [[ "${CI_COMMIT_REF_NAME}" == "feature/"* ]] || [[ "${CI_COMMIT_REF_NAME}" == "fix/"* ]]; then env="DEV";
    elif [[ "${CI_COMMIT_REF_NAME}" == "develop" ]]; then env="INT"; 
    elif [[ "${CI_COMMIT_REF_NAME}" == "release/"* ]] || [[ "${CI_COMMIT_REF_NAME}" == "bugfix/"* ]]; then env="UAT";
    elif [[ "${CI_COMMIT_REF_NAME}" == "master" ]] || [[ "${CI_COMMIT_REF_NAME}" == "hotfix/"* ]]; then env="PRD";
    else
        echo "'${CI_COMMIT_REF_NAME}' branch naming is not supported!" >&2
        exit -1
    fi

    # Get vars to be renamed    
    vars=($(printenv | egrep -o "${env}_CI_.*" | awk -F= '{print $1}'))

    # Set same variable with the final name
    exports=""
    for var in "${vars[@]}"; do
        var=$(echo ${var} | awk -F '=' '{print $1}')
        new_var=$(echo ${var} | cut -d'_' -f3-)
        exports="export $new_var=\${$var};${exports}"
    done

    # print the exports required
    echo ${exports}
}

# Validate if OS is supported
[[ "${OSTYPE}" == "linux-gnu" ]] || exitOnError "OS '${OSTYPE}' is not supported" -1

# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    function=${1}
    shift
    $function "${@}"
fi    