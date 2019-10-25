#!/bin/bash

### Define LIBNAME, CURRENT_DIR and include the base lib
### Usage: eval '${headLibScript}' at the beginning of your script
export headLibScript='LIBNAME="$(echo $(cd $(dirname ${BASH_SOURCE[0]}) >/dev/null 2>&1 && pwd) | awk -F / '\''{print $NF}'\'')"; CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})'

### Call the desired function when script is invoked directly instead of included ###
### Usage: eval '${footLibScript}' at the end of your script
export footLibScript='if [ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ]; then getArgs "function &@args" "${@}"; ${function} "${args[@]}"; fi'

### Show a info text
# usage: echoInfo <text>
function echoInfo() {
    text="${1/'\n'/$'\n'}"
    local IFS=$'\n'
    local _lines=(${text})
    local _error="INFO: "
    for _line in "${_lines[@]}"; do
        echo "${_error} ${_line}"
        _error="      "
    done
}

### Show a test in the stderr
# usage: echoError <text>
function echoError() {
    text="${1/'\n'/$'\n'}"
    local IFS=$'\n'
    local _lines=(${text})
    local _error="ERROR: "
    for _line in "${_lines[@]}"; do
        echo "${_error} ${_line}" >&2
        _error="       "
    done
}

### Exit program with text when last exit code is non-zero ###
# usage: exitOnError <output_message> [optional: forced code (defaul:exit code)]
function exitOnError {
    code=${2:-$?}
    text=${1}
    if [ "${code}" -ne 0 ]; then
        if [ ! -z "${text}" ]; then
            echoError "${text}"
        fi
        echo "Exiting..." >&2
        exit $code
    fi
}

### get arguments ###
# usage: getArgs "<arg_name1> <arg_name2> ... <arg_nameN>" ${@}
# when a variable name starts with @<var> it will take the rest of values
# when a variable name starts with &<var> it is optional and script will not fail case there is no value for it
function getArgs {

    _argsResult=0
    _args=(${1})

    for _arg in ${_args[@]}; do
        shift        
        # if has # the argument is optional        
        if [[ ${_arg} == "&"* ]]; then
            _arg=$(echo ${_arg}| sed 's/&//')
        elif [ ! "${1}" ]; then
            echoError "Values for argument '${_arg}' not found!"
            _arg=""
            ((_argsResult+=1))
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

    exitOnError "Invalid arguments at '${BASH_SOURCE[-1]}' (Line ${BASH_LINENO[-2]})\nUsage: ${FUNCNAME[1]} \"$(echo ${_args[@]})\"" ${_argsResult}
}

### Validate defined variables ###
# usage: validateVars <var1> <var2> ... <varN>
function validateVars {
    _varsResult=0
    for var in ${@}; do
        if [ -z "${!var}" ]; then
            echoError "Environment varirable '${var}' is not declared!" >&2
            ((_varsResult+=1))
        fi
    done
    exitOnError "Some variables were not found" ${_varsResult}
}

### dependencies verification ###
# usage: verifyDeps <dep1> <dep2> ... <depN>
function verifyDeps {
    _depsResult=0
    for dep in ${@}; do
        which ${dep} &> /dev/null
        if [[ $? -ne 0 ]]; then
            echoError "Binary dependency '${dep}' not found!" >&2
            ((_depsResult+=1))
        fi
    done
    exitOnError "Some dependencies were not found" ${_depsResult}
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

    getArgs "CI_COMMIT_REF_NAME @GITLAB_LIBS_BRANCHES_DEFINITION" "${@}"

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
    echoInfo "**************************************************"
    for var in "${vars[@]}"; do
        var=$(echo ${var} | awk -F '=' '{print $1}')
        new_var=$(echo ${var} | cut -d'_' -f3-)
        echoInfo "${CI_BRANCH_ENVIRONMENT} value set: '${new_var}'"
        export ${new_var}="${!var}"
    done
    echoInfo "**************************************************"
}

### Import GitLab Libs ###
# Usage: importLibs <lib1> <lib2> ... <libN>
function importLibs {

    # For each lib
    _libsResult=0
    while [ "$1" ]; do
        lib="${1}"
        lib_alias="${lib}lib"        
        lib_file="${GITLAB_LIBS_DIR}/${lib}/main.sh"
        lib_error=""

        # Check if it is in online mode to copy/update libs
        if [ ${GITLAB_LIBS_MODE} == "online" ]; then
            # Check if the lib is available from download
            if [ ! -f ${GITLAB_TMP_DIR}/libs/${lib}/main.sh ]; then
                echoError "GITLAB Library '${lib}' not found!"
                lib_error="true"
                ((_libsResult+=1))
            else
                # Create lib dir and copy
                mkdir -p ${GITLAB_LIBS_DIR}/${lib} && cp -r ${GITLAB_TMP_DIR}/libs/${lib}/* ${GITLAB_LIBS_DIR}/${lib}
                exitOnError "Could not copy the '${lib_alias}' library files"

                # Make the lib executable
                chmod +x ${lib_file}
            fi
        # Check if the lib is available locally
        elif [ ! -f "${lib_file}" ]; then
            echoError "GITLAB Library '${lib}' not found! (was it downloaded already in online mode?)"
            lib_error="true"
            ((_libsResult+=1))
        fi

        # Check if there was no error importing the lib files
        if [ ! ${lib_error} ]; then
            # Import lib
            source ${lib_file}
            exitOnError "Error importing '${lib_alias}'"

            # Get lib function names
            functs=($(bash -c '. '${lib_file}' &> /dev/null; typeset -F' | awk '{print $NF}'))

            # Rename functions
            funcCount=0
            for funct in ${functs[@]}; do

                # if not an internal function neiter a private one (i.e: _<var>)
                if [[ ! "${GITLAB_LIBS_FUNCT_LOADED[@]}" =~ "${funct}" && ${funct} != "_"* ]]; then
                    # echoInfo "  -> ${lib_alias}.${funct}()"
                    eval "$(echo "${lib_alias}.${funct}() {"; echo '    if [[ ${-//[^e]/} == e ]]; then '${lib_file} ${funct} "\"\${@}\""'; return; fi'; declare -f ${funct} | tail -n +3)"
                    unset -f ${funct}
                    ((funcCount+=1))
                fi
            done

            echoInfo "Imported GITLAB Library '${lib_alias}' (${funcCount} functions)"
        fi

        # Go to next arg
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "Some GitLab Libraries were not found!" ${_libsResult}
}

### Import GitLab Libs sub-modules ###
# Usage: importSubModules <mod1> <mod2> ... <modN>
function importSubModules {

    # For each sub-module
    _modsResult=0
    while [ "${1}" ]; do        
        module_file="${CURRENT_DIR}/${1}"

        # Check if the module exists
        if [ ! -f "${module_file}" ]; then
            echoError "GITLAB Library sub-module '${LIBNAME}/${1}' not found! (was it downloaded already in online mode?)"
            ((_modsResult+=1))
        else
            # Import sub-module
            #echoInfo "Importing module: '${module_file}'..."
            source ${module_file}
        fi
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "Some GitLab Libraries sub-modules were not found!" ${_modsResult}
}

# Verify bash version
$(awk 'BEGIN { exit ARGV[1] < 4.3 }' ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})
exitOnError "Bash version needs to be '4.3' or newer (current: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})"

# Export all functions for sub-bash executions
export GITLAB_LIBS_FUNCT_LOADED=$(typeset -F | awk '{print $NF}')
for funct in ${GITLAB_LIBS_FUNCT_LOADED[@]}; do
    export -f ${funct}
done

# Export internal functions
eval "${footLibScript}"
