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
            local newline=$'\n'
            local has_default=false

            # Get each defined var
            for var_name in $(echo "${lineFound}" | cut -d '"' -f2); do
                local var_value="\${1}"
                local var_required=true
                local var_rest=false

                if [[ "${var_name}" == "@"* ]]; then # @Rest
                  var_name=${var_name/@};
                  var_rest=true
                fi

                if [[ "${var_name}" == *"="* ]]; then # Default variables=default
                  local name_value=(${var_name/=/ })
                  var_name=${name_value[0]}
                  var_value="\${1:-${name_value[1]}}"
                  var_required=false
                  unset -v name_value
                  has_default=true
                elif [[ "${has_default}" == "true" ]]; then
                  echoError "Warning! REQUIRED variable found AFTER default!"
                fi

                if [[ "${var_required}" == "true" ]]; then
                    reworkedCode="${reworkedCode} [[ ! \"\${1}\" ]] && echoError \"Values for argument '${var_name}' not found!\"${newline}";
                fi
                local var_index=
                if [[ "${var_rest}" == "true" ]]; then
                  var_index="[\${rest_index}]"
                  reworkedCode="${reworkedCode} local rest_index=0; while [ \${1} ]; do${newline}"
                fi
                reworkedCode="${reworkedCode} local ${var_name}${var_index}=${var_value}; shift;${newline}"
                if [[ "${var_rest}" == "true" ]]; then
                  var_index="[\${rest_index}]"
                  reworkedCode="${reworkedCode} ((rest_index+=1));${newline}done;${newline}"
                  break
                fi
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
