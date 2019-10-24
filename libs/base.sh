#!/bin/bash

### Define CURRENT_DIR and include the base lib
### Usage: eval '${importBaseLib}' at the beginning of your script
export importBaseLib='CURRENT_DIR=$(dirname ${BASH_SOURCE[0]}); if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then source ${CURRENT_DIR}/../base.sh; fi'

### Call the desired function when script is invoked directly instead of included ###
### Usage: eval '${useInternalFunctions}' at the end of your script
export useInternalFunctions='if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then getArgs "function &@args" ${@}; ${function} "${args[@]}"; fi'

### Exit program with text when last exit code is non-zero ###
# usage: exitOnError <output_message> [optional: forced code (defaul:exit code)]
function exitOnError {
    code=${2:-$?}
    text=${1}
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
# Usage: convertEnvVars <GITLAB_LIBS_BRANCHES_DEFINITION>
# Example: [ENV]_CI_[VAR_NAME] -> [VAR NAME]  ### 
#
# GITLAB_LIBS_BRANCHES_DEFINITION: "<def1> <def2> ... <defN>"
# Definition: <branch>:<env> (example: feature/*:DEV)
# GITLAB_LIBS_BRANCHES_DEFINITION example: "feature/*:DEV fix/*:DEV develop:INT release/*:UAT bugfix/*:UAT master:PRD hotfix/*:PRD"
#
function convertEnvVars {

    getArgs "CI_COMMIT_REF_NAME @GITLAB_LIBS_BRANCHES_DEFINITION" ${@}

    # Set environment depending on branches definition
    for _definition in "${GITLAB_LIBS_BRANCHES_DEFINITION[@]}"; do
        _branch=${_definition%:*}
        _environment=${_definition#*:}

        # Check if matched current definition
        if [[ ${CI_COMMIT_REF_NAME} == ${_branch} ]]; then
            CI_BRANCH_ENVIRONMENT=${_environment};
            break
        fi
    done

    # Check if found an environment
    [ ${CI_BRANCH_ENVIRONMENT} ] || exitOnError "'${CI_COMMIT_REF_NAME}' branch naming is not supported, check your GITLAB_LIBS_BRANCHES_DEFINITION!" -1

    # Get vars to be renamed    
    vars=($(printenv | egrep -o "${CI_BRANCH_ENVIRONMENT}_CI_.*=" | awk -F= '{print $1}'))

    # Set same variable with the final name
    echo "**************************************************"
    for var in "${vars[@]}"; do
        var=$(echo ${var} | awk -F '=' '{print $1}')
        new_var=$(echo ${var} | cut -d'_' -f3-)
        echo "${CI_BRANCH_ENVIRONMENT} value set: '${new_var}'"
        export ${new_var}="${!var}"
    done
    echo "**************************************************"
}

### Import GitLab Libs ###
# Usage: importLibs <lib1> <lib2> ... <libN>
function importLibs {

    # Expand aliases (old approach)
    if [ "${CI}" ]; then shopt -s expand_aliases; fi

    # For each lib
    result=0
    while [ "$1" ]; do
        lib="${1}"
        lib_alias="${lib}lib"        
        lib_file="${GITLAB_LIBS_DIR}/${lib}/main.sh"
        lib_error=""

        # Check if it is in online mode to copy/update libs
        if [ ${GITLAB_LIBS_ONLINE_MODE} ]; then
            # Check if the lib is available from download
            if [ ! -f ${GITLAB_TMP_DIR}/libs/${lib}/main.sh ]; then
                echo "GITLAB Library '${lib}' not found!"
                lib_error="true"
                ((result+=1))
            else
                # Create lib dir and copy
                mkdir -p ${GITLAB_LIBS_DIR}/${lib} && cp -r ${GITLAB_TMP_DIR}/libs/${lib}/* ${GITLAB_LIBS_DIR}/${lib}
                exitOnError "Could not copy the '${lib_alias}' library files"

                # Make the lib executable
                chmod +x ${lib_file}
            fi
        # Check if the lib is available locally
        elif [ ! -f "${lib_file}" ]; then
            echo "GITLAB Library '${lib}' not found!"
            lib_error="true"
            ((result+=1))
        fi

        # Check if there was no error importing the lib files
        if [ ! ${lib_error} ]; then
            # Alias to execute the lib as subprocess (to use in .gitlab-ci.yml)
            if [ "${CI}" ]; then alias ${lib_alias}=${lib_file}; fi

            # Import lib
            source ${lib_file}
            exitOnError "Error importing '${lib_alias}'"
            
            # Get lib function names
            functs=($(bash -c '. '${lib_file}' &> /dev/null; typeset -F' | awk '{print $NF}'))

            # Rename functions
            funcCount=0
            for funct in ${functs[@]}; do
                if [[ ${funct} != "_"* ]]; then
                    # echo "  -> ${lib_alias}.${funct}()"
                    eval "$(echo "${lib_alias}.${funct}() {"; echo '    if [[ ${-//[^e]/} == e ]]; then echo "ERROR: ${FUNCNAME}() - Using '"'set -e'"' is not supported! (executing in GitLab Pipeline? use: '"'${lib_alias} ${funct} <args>'"' instead)"; exit -1; fi'; declare -f ${funct} | tail -n +3)"
                    unset -f ${funct}
                    ((funcCount+=1))
                fi
            done

            echo "Imported GITLAB Library '${lib_alias}' (${funcCount} functions)"
        fi

        # Go to next arg
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "GITLAB Library '${lib}' not found!" ${result}
}

# Export internal functions
eval "${useInternalFunctions}"
