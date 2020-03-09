#!/bin/bash
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

# Rework imported cde
function __rework() {
    # For each instance found
    # TODO: allow getArgs in comments/strings
    body=$(echo "${body}" | grep getArgs | while read -r lineFound; do
        if [ "${lineFound}" ]; then
            local var
            local val

            local reworkedCode=""
            local reworked=""
            local newline=$'\n'

            # Get each defined var
            for var in $(echo "${lineFound}" | cut -d '"' -f2); do
                if [[ ${var} == *"="* ]]; then # Default variables=default
                  local var_value=(${var/=/ })
                  reworkedCode="${reworkedCode} local ${var_value[0]}=\${1:-${var_value[1]}}; shift;${newline}"
                  unset -v var_value
                elif [[ ${var} == "@"* ]]; then # Rest
                  var=${var/@};
                  reworkedCode="${reworkedCode}
  local rest_index=0;
  while [ \${1} ]; do
     local ${var}[\${rest_index}]=\${1}; shift;
     ((rest_index+=1)); 
  done;${newline}"
                  break
                else
                  reworkedCode="${reworkedCode} [[ ! \"\${1}\" ]] && echoError \"Values for argument '${var}' not found!\";
local ${var}=\${1}; shift;${newline}"
                fi
                ((arg_pos+=1))
            done
            # Update the code
            body=${body/"${lineFound}"/"${reworkedCode}"}
        fi
        echo "${body}"
    done)
}

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

