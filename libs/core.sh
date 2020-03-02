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

# Check if not being included twice
if [ "${DOLIBS_CORE_FUNCT}" ]; then 
    exitOnError "You cannot include twice $(basename ${BASH_SOURCE[0]})" -1
fi

# Definitions
export DOLIBS_LIB_FILE=${DOLIBS_DIR}/lib.sh
export DOLIBS_MAIN_FILE="main.sh"

### Consume an internal library ###
# Usage: self <function> <args>
function self() {
    _function=${1}; shift
    _namespace=${FUNCNAME[1]/$(echo ${FUNCNAME[1]} | awk -F . '{print "."$NF}')/}
    ${_namespace}.${_function} "${@}"
    return ${?}
}

### Consume an internal library ###
# Usage: assign <retvar>=<function> <args>
############################################################
# Obs: your function needs to return values on _return var #
############################################################
function assign() {

    local _assigments=${1}; shift
    local _returnVar=${_assigments%%"="*}
    local _returnFunc=${_assigments##*"="}    

    # Case function is self
    if [ ${_returnFunc} == "self" ]; then
        _returnFunc=${1}; shift
        _namespace=${FUNCNAME[1]/$(echo ${FUNCNAME[1]} | awk -F . '{print "."$NF}')/}
        _returnFunc=${_namespace}.${_returnFunc}
    fi

    # If desired varibla is not return
    if [[ ${_returnVar} != "_return" ]]; then 
        # Store last _return value
        local _returnTmp=("${_return[@]}")
        # Clean new _return
        unset _return
    fi

    # Execute the function and store the result    
    ${_returnFunc} "${@}"
    local _result=${?}

    if [[ ${_returnVar} != "_return" ]]; then 
        # Copy _return to the desired variable
        local _returnVal
        local _argPos=0
        for _returnVal in "${_return[@]}"; do 
            eval "$(echo ${_returnVar}[${_argPos}]='${_returnVal}')"
            ((_argPos+=1))
        done
        # Copy back _return value
        _return=("${_returnTmp[@]}")
    fi

    return ${_result}
}

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
function exitOnError() {
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

### Validate defined variables ###
# usage: validateVars <var1> <var2> ... <varN>
function validateVars() {
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
function verifyDeps() {
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

### get arguments ###
# usage: getArgs "<arg_name1> <arg_name2> ... <arg_nameN>" ${@}
# when a variable name starts with @<var> it will take the rest of values
# when a variable name starts with &<var> it is optional and script will not fail case there is no value for it
function getArgs() {

    local _result=0
    local _args=(${1})
    local _var

    for _var in "${_args[@]}"; do
        shift        
        # if has # the argument is optional
        if [[ ${_var} == "&"* ]]; then
            #_var=$(echo ${_var}| sed 's/&//')
            _var=${_var/&/}
        elif [ ! "${1}" ]; then
            echoError "Values for argument '${_var}' not found!"
            _var=""
            ((_result+=1))
        fi

        # if has @ will get all the rest of arguments
        if [[ "${_var}" == "@"* ]]; then
            #_var=$(echo ${_var}| sed 's/@//')
            _var=${_var/@/}            
            local _argPos=0
            unset -v ${_var}
            while [ "${1}" ]; do         
                #echo ${_var}[${_argPos}]="${1}"
                eval "$(echo ${_var}[${_argPos}]='${1}')"
                shift; ((_argPos+=1))
            done
        # else get only one argument
        elif [ "${_var}" ]; then
            eval "$(echo ${_var}='${1}')"
        fi
    done

    exitOnError "Invalid arguments at '${BASH_SOURCE[-1]}' (Line ${BASH_LINENO[-2]})\nUsage: ${FUNCNAME[1]} \"$(echo ${_args[@]})\"" ${_result}
}

### Consume an internal library ###
# Usage: _createLibFunctions <lib alias> <func1> <func2> ... <funcN>
function _createLibFunctions() {

    local _libFuncts
    getArgs "&_libAlias &_funcHeader &@_libFuncts" "${@}"

    # Make as part of do namespace
    local _libAlias="do"$([ ! "${_libAlias}" ] || echo ".${_libAlias}")

    # Remove Core functions
    for _coreFunc in ${DOLIBS_CORE_FUNCT[@]}; do _libFuncts=("${_libFuncts[@]/${_coreFunc}}"); done

    # Rename functions
    _funcCount=0
    for _libFunct in ${_libFuncts[@]}; do
        # If function is not already imported
        if [[ ${_libFunct} != "do."* ]]; then
            # New lib name
            _libFunctNew=${_libAlias}.${_libFunct##*.}

            # Rework the function            
            eval "$(echo "${_libFunctNew}() {"; echo ${_funcHeader}; echo 'if [ ${-//[^e]/} ]; then set +e; ${FUNCNAME} '"\"\${@}\""'; _result=${?}; set -e; return ${_result}; fi'; declare -f ${_libFunct} | tail -n +3)"

            # Unset old function name
            unset -f ${_libFunct}

            # Export the new function for sub-processes
            export -f ${_libFunctNew}

            # Debug
            #echo "  -> ${_libFunctNew}()"
            ((_funcCount+=1))
        fi
    done
}

# Verify bash version
# awk 'BEGIN { exit ARGV[1] < 4.3 }' ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}
# exitOnError "Bash version needs to be '4.3' or newer (current: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})"

# Export all functions for sub-bash executions
export DOLIBS_CORE_FUNCT=$(typeset -F | awk '{print $NF}')
for funct in ${DOLIBS_CORE_FUNCT[@]}; do
    export -f ${funct}
done

# Common library entrypoint validation
[ -f ${DOLIBS_LIB_FILE} ] || exitOnError "DEVOPS Library '${DOLIBS_LIB_FILE}' not found! (try online mode)" ${?}

# Import dolib
source ${DOLIBS_LIB_FILE} "do" ${DOLIBS_DIR}
exitOnError "Error importing 'dolib' library"

# Import DevOps Libs functions
_createLibFunctions "" "" $(bash -c '. '"${DOLIBS_LIB_FILE} "do" ${DOLIBS_DIR}"' &> /dev/null; typeset -F' | awk '{print $NF}')