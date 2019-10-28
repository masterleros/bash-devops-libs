#!/bin/bash

# Check if not being included twice
if [ "${DEVOPS_LIBS_FUNCT_LOADED}" ]; then 
    exitOnError "You cannot include twice $(basename ${BASH_SOURCE[0]})" -1
fi

# Definitions
export DEVOPS_LIBS_MAIN_FILE="main.sh"

### Show a info text
# usage: echoInfo <text>
function echoInfo() {
    local IFS=$'\n'
    local _text="${1/'\n'/$'\n'}"
    local _lines=(${_text})
    local _textToPrint="INFO:  "
    for _line in "${_lines[@]}"; do
        echo "${_textToPrint} ${_line}"
        _textToPrint="       "
    done
}

### Show a test in the stderr
# usage: echoError <text>
function echoError() {
    local IFS=$'\n'
    local _text="${1/'\n'/$'\n'}"
    local _lines=(${_text})
    local _textToPrint="ERROR: "
    for _line in "${_lines[@]}"; do
        echo "${_textToPrint} ${_line}" >&2
        _textToPrint="       "
    done
}

### Exit program with text when last exit code is non-zero ###
# usage: exitOnError <output_message> [optional: forced code (defaul:exit code)]
function exitOnError {
    local _errorCode=${2:-$?}
    local _errorText=${1}
    if [ "${_errorCode}" -ne 0 ]; then
        if [ ! -z "${_errorText}" ]; then
            echoError "${_errorText}"
        else
            echoError "At '${BASH_SOURCE[-1]}' (Line ${BASH_LINENO[-2]})"
        fi
        echo "Exiting (${_errorCode})..."
        exit ${_errorCode}
    fi
}

### get arguments ###
# usage: getArgs "<arg_name1> <arg_name2> ... <arg_nameN>" ${@}
# when a variable name starts with @<var> it will take the rest of values
# when a variable name starts with &<var> it is optional and script will not fail case there is no value for it
function getArgs {

    local _result=0
    local _args=(${1})

    for _arg in ${_args[@]}; do
        shift        
        # if has # the argument is optional
        if [[ ${_arg} == "&"* ]]; then
            _arg=$(echo ${_arg}| sed 's/&//')
        elif [ ! "${1}" ]; then
            echoError "Values for argument '${_arg}' not found!"
            _arg=""
            ((_result+=1))
        fi

        # if has @ will get all the rest of args
        if [[ "${_arg}" == "@"* ]]; then
            _arg=$(echo ${_arg}| sed 's/@//')
            while [ "${1}" ]; do                
                eval "${_arg}+=('${1}')"; shift
            done
        elif [ "${_arg}" ]; then
            eval "${_arg}='${1}'"
        fi
    done

    exitOnError "Invalid arguments at '${BASH_SOURCE[-1]}' (Line ${BASH_LINENO[-2]})\nUsage: ${FUNCNAME[1]} \"$(echo ${_args[@]})\"" ${_result}
}

### Validate defined variables ###
# usage: validateVars <var1> <var2> ... <varN>
function validateVars {
    local _result=0
    for var in ${@}; do
        if [ -z "${!var}" ]; then
            echoError "Environment varirable '${var}' is not declared!" >&2
            ((_result+=1))
        fi
    done
    return ${_result}
}

### dependencies verification ###
# usage: verifyDeps <dep1> <dep2> ... <depN>
function verifyDeps {
    local _result=0
    for dep in ${@}; do
        which ${dep} &> /dev/null
        if [[ $? -ne 0 ]]; then
            echoError "Binary dependency '${dep}' not found!" >&2
            ((_result+=1))
        fi
    done
    return ${_result}
}

### This funciton will map environment variables to the final name ###
# Usage: convertEnvVars <DEVOPS_LIBS_BRANCHES_DEFINITION>
# Example: [ENV]_CI_[VAR_NAME] -> [VAR NAME]  ### 
#
# DEVOPS_LIBS_BRANCHES_DEFINITION: "<def1> <def2> ... <defN>"
# Definition: <branch>:<env> (example: feature/*:DEV)
# DEVOPS_LIBS_BRANCHES_DEFINITION example: "feature/*:DEV fix/*:DEV develop:INT release/*:UAT bugfix/*:UAT master:PRD hotfix/*:PRD"
#
function convertEnvVars {

    getArgs "CI_COMMIT_REF_NAME @DEVOPS_LIBS_BRANCHES_DEFINITION" "${@}"

    # Set environment depending on branches definition
    for _definition in "${DEVOPS_LIBS_BRANCHES_DEFINITION[@]}"; do
        _branch=${_definition%:*}
        _environment=${_definition#*:}

        # Check if matched current definition
        if [[ ${CI_COMMIT_REF_NAME} == ${_branch} ]]; then
            CI_BRANCH_ENVIRONMENT=${_environment};
            break
        fi
    done

    # Check if found an environment
    [ ${CI_BRANCH_ENVIRONMENT} ] || exitOnError "'${CI_COMMIT_REF_NAME}' branch naming is not supported, check your DEVOPS_LIBS_BRANCHES_DEFINITION!" -1

    # Get vars to be renamed    
    vars=($(printenv | egrep -o "${CI_BRANCH_ENVIRONMENT}_CI_.*=" | awk -F= '{print $1}'))

    # Set same variable with the final name
    echoInfo "####################################################"
    for var in "${vars[@]}"; do
        var=$(echo ${var} | awk -F '=' '{print $1}')
        new_var=$(echo ${var} | cut -d'_' -f3-)
        echoInfo "${CI_BRANCH_ENVIRONMENT} value set: '${new_var}'"
        export ${new_var}="${!var}"
    done
    echoInfo "####################################################"
}

### Import DevOps Lib files ###
# Usage: _importLibFiles <lib>
function _importLibFiles() {
    
    getArgs "_lib" "${@}"
    local _libAlias=${_lib}lib
    local _libPath=${DEVOPS_LIBS_PATH}/${_lib}
    local _libTmpPath=${DEVOPS_LIBS_TMP_PATH}/libs/${_lib}
    local _libTmpMain=${_libTmpPath}/${DEVOPS_LIBS_MAIN_FILE}

    # Check if the lib is available from download
    if [ -f ${_libTmpMain} ]; then
        # Create lib dir and copy
        mkdir -p ${_libPath} && cp -r ${_libTmpPath}/* ${_libPath}
        exitOnError "Could not copy the '${_libAlias}' library files"
        return 0        
    fi

    echoError "DEVOPS Library '${_lib}' not found! (was it downloaded already?)"
    return 1
}

### Consume an internal library ###
# Usage: self <function> <args>
function self() {
    getArgs "function &@args" "${@}"
    ${FUNCNAME[1]/.*/}.${function} "${args[@]}"
    return ${?}
}

### Import DevOps Libs ###
# Usage: importLibs <lib1> <lib2> ... <libN>
function importLibs {

    # If executed in context of set -e
    if [ ${-//[^e]/} ]; then set +e; ${FUNCNAME} "${@}"; set -e; return ${?}; fi

    # Common library entrypoint
    local _libFile="${DEVOPS_LIBS_PATH}/lib.sh"
    [ -f ${_libFile} ] || exitOnError "DEVOPS Library '${_libFile}' not found! (try online mode)" ${?}

    # For each lib
    local _result=0
    while [ "${1}" ]; do
        local _lib="${1}"
        local _libAlias=${_lib}lib
        local _libPath=${DEVOPS_LIBS_PATH}/${_lib}
        local _libMain=${_libPath}/${DEVOPS_LIBS_MAIN_FILE}
        local _libTmpPath=${DEVOPS_LIBS_TMP_PATH}/libs/${_lib}
        local _libTmpMain=${_libTmpPath}/${DEVOPS_LIBS_MAIN_FILE}

        # if lib was already imported
        if [[ $(typeset -F | grep "${_libAlias}.") ]]; then
            echoInfo "DEVOPS Library '${_libAlias}' already imported!"            
        else
            # Check if it is in online mode to copy/update libs
            if [ "${DEVOPS_LIBS_MODE}" == "online" ]; then
                # Include the lib
                _importLibFiles ${_lib}
            # Check if the lib is available locally
            elif [ ! -f "${_libMain}" ]; then
                # In in auto mode
                if [[ ${DEVOPS_LIBS_MODE} == "auto" && ! -f "${_libTmpMain}" ]]; then
                    echoInfo "AUTO MODE - '${_libAlias}' is not installed neither found in cache, cloning code"

                    # Try to clone the lib code                
                    devOpsLibsClone
                    exitOnError "It was not possible to clone the library code"
                fi

                # Include the lib
                _importLibFiles ${_lib}
            fi

            # Check if there was no error importing the lib files
            if [ ${?} -eq 0 ]; then
                # Import lib
                source ${_libFile} ${_lib} ${_libPath}
                exitOnError "Error importing '${_libMain}'"

                # Get lib function names
                local _libFuncts=($(bash -c '. '"${_libFile} ${_lib} ${_libPath}"' &> /dev/null; typeset -F' | awk '{print $NF}'))

                # Rename functions
                _funcCount=0
                for _libFunct in ${_libFuncts[@]}; do
                    # if not another imported lib
                    # if not an internal function
                    if [[ ! ${_libFunct} =~ "lib." && ! "${DEVOPS_LIBS_FUNCT_LOADED[@]}" =~ "${_libFunct}" ]]; then 

                        _libFunctNew=${_libAlias}.${_libFunct}
                        #echoInfo "  -> ${_libFunctNew}()"
                        eval "$(echo "${_libFunctNew}() {"; echo 'if [ ${-//[^e]/} ]; then set +e; ${FUNCNAME} '"\"\${@}\""'; set -e; return ${?}; fi'; declare -f ${_libFunct} | tail -n +3)"
                        ((_funcCount+=1))

                        # Unset old function name and Export the new function for sub-processes
                        unset -f ${_libFunct}
                        export -f ${_libFunctNew}                    
                    fi
                done
                echoInfo "Imported DEVOPS Library '${_libAlias}' (${_funcCount} functions)" 
            else 
                ((_result+=1)); 
            fi
        fi

        # Go to next arg
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "Some DevOps Libraries were not found!" ${_result}
}

### Import DevOps Libs sub-modules ###
# Usage: importSubModules <mod1> <mod2> ... <modN>
function importSubModules {

    # For each sub-module
    local _result=0
    while [ "${1}" ]; do        
        module_file="${CURRENT_LIB_PATH}/${1}.sh"

        # Check if the module exists
        if [ ! -f "${module_file}" ]; then
            echoError "DEVOPS Library sub-module '${CURRENT_LIB}/${1}' not found! (was it downloaded already in online mode?)"
            ((_result+=1))
        else
            # Import sub-module
            #echoInfo "Importing module: '${module_file}'..."
            source ${module_file}
        fi
        shift
    done

    # Case any libs was not found, exit with error
    exitOnError "Some DevOps Libraries sub-modules were not found!" ${_result}
}

# Verify bash version - not required, declare -n not longer used
# exitOnError "Bash version needs to be '4.3' or newer (current: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})" $(awk 'BEGIN { exit ARGV[1] < 4.3 }' ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}; echo $?)

# Export all functions for sub-bash executions
export DEVOPS_LIBS_FUNCT_LOADED=$(typeset -F | awk '{print $NF}')
for funct in ${DEVOPS_LIBS_FUNCT_LOADED[@]}; do
    export -f ${funct}
done
