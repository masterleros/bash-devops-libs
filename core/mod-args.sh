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
    ############## Header ##############
    # Add to the function the lib context
    _body="local SELF_LIB='${_lib}'; local SELF_LIB_DIR='${_libDir}'; ${_body}"
    ############## Header ##############

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

# @description Execute a function within same library module
# @exitcode any passed command execution exit code
# @example 
#   self <function> <args>
#
#   # Can be used in combination of assign
#   assign <var>=self <function> <args>
function self() {
    _function=${1}; shift
    if [ "${SELF_LIB}" ]; then 
        "${SELF_LIB}.${_function}" "${@}"
    else
        "${_function}" "${@}"
    fi
    return ${?}
}

# @description Assign the returned value to a variable
#   > Obs: your function needs to return values on the global `_return` variable
# @arg $@ list variable=command and args
# @exitcode any passed command execution exit code
# @example
#   function myFunc()
#   {
#       _return="value"
#   }
#   assign var=myFunc <args>
#   echo ${var} # this will print 'value'
function assign() {

    local _assigments=${1}; shift
    local _returnVar=${_assigments%%"="*}
    local _returnFunc=${_assigments##*"="}    

    # Case function is self
    if [ "${_returnFunc}" == "self" ]; then
        _returnFunc=${1}; shift
        _returnFunc=${SELF_LIB}.${_returnFunc}        
    fi

    # If desired variable is not return
    if [ "${_returnVar}" != "_return" ]; then 
        # Store last _return value
        local _returnTmp=("${_return[@]}")
    fi

    # Clear _return, execute the function and store the exit code    
    unset _return
    ${_returnFunc} "${@}"
    local _eCode=${?}

    if [ "${_returnVar}" != "_return" ]; then 
        # Copy _return to the desired variable
        local _declaration=$(declare | egrep ^_return=)
        eval "${_declaration/_return=/${_returnVar}=}"
        unset _return

        # Copy back _return value if existed
        [ ! "${_returnTmp}" ] || _return=("${_returnTmp[@]}")
    fi

    return ${_eCode}
}

# @description Process the passed values in the required variables \
# - A variable starting with `@`<var> will take the rest of values \
# - A variable ending with <var>`=` is optional and script will not fail case there is no value for it
# - A variable having equal plus value, as <var>`=`<default-value> is optional and will use default value when argument is not provided
# @example
#   # If any of the arguments is not provided, it will fail
#   getArgs "var1 va2 ... varN>"
#   echo ${var1} # will print what was passed in ${1}
#   echo ${var2} # will print what was passed in ${2}
#   # Same for the rest of arguments
# @example
#   # var2 will be an array and will take all the remaining arguments 
#   getArgs "var1 @var2"
#   echo ${var1} # will print what was passed in ${1}
#   echo ${var2[@]} # will print all the rest of passed values
# @example
#   # var2 is optional and if not passed will print nothing
#   getArgs "var1 var2="
#   echo ${var1} # will print what was passed in ${1}
#   echo ${var2} # optional
function getArgs() {
  echoError "getArgs call was not been reworked! (have you used dolibReworkFunction() on your function?)"
  exit -1
}
