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
# when a variable name starts with @<var> it will take the rest of values
# when a variable name starts with &<var> it is optional and script will not fail case there is no value for it
function getArgs {
    retval=0
    _args=(${1})

    for _arg in ${_args[@]}; do
        shift        
        # if has # the argument is optional        
        if [[ ${_arg} == "&"* ]]; then
            _arg=$(echo ${_arg}| sed 's/&//')
        elif [ ! "${1}" ]; then
            echo "Values for argument '${_arg}' not found!"
            _arg=""
            ((retval+=1))
        fi

        # if has @ will get all the rest of args
        if [[ "${_arg}" == "@"* ]]; then
            _arg=$(echo ${_arg}| sed 's/@//')
            declare -n _ref=${_arg}; _ref=("${@}")
            return        
        elif [ "${_arg}" ]; then
            declare -n _ref=${_arg}; _ref=${1}
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
#
# CI_BRANCHES_DEFINITION: "<def1> <def2> ... <defN>"
# Definition: <branch>:<env> (example: feature/*:DEV)
# CI_BRANCHES_DEFINITION example: "feature/*:DEV fix/*:DEV develop:INT release/*:UAT bugfix/*:UAT master:PRD hotfix/*:PRD"
#
function printEnvMappedVarsExports {
    
    validateVars CI_COMMIT_REF_NAME CI_BRANCHES_DEFINITION

    # Set environment depending on branches definition    
    for _definition in ${CI_BRANCHES_DEFINITION}; do
        _branch=${_definition%:*}
        _environment=${_definition#*:}

        # Check if matched current definition
        if [[ ${CI_COMMIT_REF_NAME} == ${_branch} ]]; then
            CI_BRANCH_ENVIRONMENT=${_environment};            
            break
        fi
    done
    
    # Check if found an environment
    [ ${CI_BRANCH_ENVIRONMENT} ] || exitOnError "'${CI_COMMIT_REF_NAME}' branch naming is not supported!" -1

    # Get vars to be renamed    
    vars=($(printenv | egrep -o "${CI_BRANCH_ENVIRONMENT}_CI_.*" | awk -F= '{print $1}'))

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

###############################################################################
# Call the desired function when script is invoked directly instead of included
if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then
    getArgs "function &@args" ${@}
    ${function} "${args[@]}"
fi
###############################################################################