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
### Consume an internal library ###
# Usage: self <function> <args>
function self() {
    _function=${1}; shift
    "${SELF_LIB}.${_function}" "${@}"
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
    if [ "${_returnFunc}" == "self" ]; then
        _returnFunc=${1}; shift
        _returnFunc=${SELF_LIB}.${_returnFunc}        
    fi

    # If desired varibla is not return
    if [ "${_returnVar}" != "_return" ]; then 
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
            eval $(echo "${_returnVar}"["${_argPos}"]="'${_returnVal}'")
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
            #_var=$(echo "${_var}"| sed 's/&//')
            _var=${_var/&/}
        elif [ ! "${1}" ]; then
            echoError "Values for argument '${_var}' not found!"
            _var=""
            ((_result+=1))
        fi

        # if has @ will get all the rest of arguments
        if [[ "${_var}" == "@"* ]]; then
            #_var=$(echo "${_var}"| sed 's/@//')
            _var=${_var/@/}
            local _argPos=0
            unset -v ${_var} # Clean up the array before assign values
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