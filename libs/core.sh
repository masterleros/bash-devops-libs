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
echoInfo "Loading core library..."

# Verify bash version
awk 'BEGIN { exit ARGV[1] < 4.3 }' ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}
exitOnError "Bash version needs to be '4.3' or newer (current: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})"

# Check if not being included twice
[ ! "${DOLIBS_CORE_FUNCT}" ]; exitOnError "You cannot include twice the core library"

# Common library entrypoint validation
[ -f ${DOLIBS_LIB_FILE} ]; exitOnError "DEVOPS Library '${DOLIBS_LIB_FILE}' not found! (try online mode)"

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
            _var=$(echo ${_var}| sed 's/&//')
        elif [ ! "${1}" ]; then
            echoError "Values for argument '${_var}' not found!"
            _var=""
            ((_result+=1))
        fi

        # if has @ will get all the rest of arguments
        if [[ "${_var}" == "@"* ]]; then
            _var=$(echo ${_var}| sed 's/@//')
            local _argPos=0
            while [ "${1}" ]; do         
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
# Usage: _createLibFunctions <lib_dir> <lib_alias> <func_header>
function _createLibFunctions() {

    getArgs "_libDir &_libAlias" "${@}"

    # Set the function local context
    local _funcHeader='
local CURRENT_LIB='${_libAlias}'
local CURRENT_LIB_DIR='${_libDir}'
if [ ${-//[^e]/} ]; then 
    set +e
    ${FUNCNAME} "${@}"
    _result=${?}
    set -e
    return ${_result}
fi
'

    # Make as part of do namespace
    local _libAlias="do"$([ ! "${_libAlias}" ] || echo ".${_libAlias}")

    # Import lib functions
    source ${DOLIBS_LIB_FILE} ${_libAlias} ${_libDir}
    exitOnError "Error importing '${_libDir}/${DOLIBS_MAIN_FILE}'"

    # Get the lib funcions
    local _libFuncts=($(bash -c '. '"${DOLIBS_LIB_FILE} ${_libAlias} ${_libDir}"' &> /dev/null; typeset -F' | awk '{print $NF}'))    

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
            eval "$(echo "${_libFunctNew}() {"; echo "${_funcHeader}"; declare -f ${_libFunct} | tail -n +3)"

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

# Export all core functions for sub-bash executions 
# so that are not included when listing includes 
# functions when importing others
export DOLIBS_CORE_FUNCT=$(typeset -F | awk '{print $NF}')
for funct in ${DOLIBS_CORE_FUNCT[@]}; do
    export -f ${funct}
done

# Import main DevOps Libs functions
_createLibFunctions ${DOLIBS_DIR}

