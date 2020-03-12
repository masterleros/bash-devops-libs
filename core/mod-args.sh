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
    local IFS='\n'
    for lineFound in "$(echo "${_body}" | grep getArgs)"; do
        if [ "${lineFound}" ]; then
            local reworkedCode=""
            local has_default=false
            local arg_index=1
            local var_names=("$(echo "${lineFound}" | cut -d '"' -f2)")
            local arg_expected=0

            # Get each defined var
            local IFS=' '
            local var_name
            for var_name in ${var_names[@]}; do
                local var_value="\${${arg_index}}"
                local var_required=true
                local var_rest=false

                # If it is a @Rest
                if [[ "${var_name}" == "@"* ]]; then
                    var_name=${var_name/@};
                    var_rest=true
                    var_value="(\"\${@}\")"
                fi

                # If was assigned a default, e.g: variables=default
                if [[ "${var_name}" == *"="* ]]; then 
                    local name_value=(${var_name/=/ })
                    var_name=${name_value[0]}
                    if [[ "${var_rest}" == "true" ]]; then
                        var_value="(\"\${@:-${name_value[1]}}\")"
                    else
                        var_value="\"\${${arg_index}:-${name_value[1]}}\""
                    fi
                    unset -v name_value
                    var_required=false
                    has_default=true

                else
                    ((arg_expected+=1))

                    # If there was a default value before a required one
                    if [[ "${has_default}" == "true" ]]; then
                        echoWarn "REQUIRED variable found AFTER default! (${BASH_SOURCE[-1]}' - Line ${BASH_LINENO[-2]})"
                    fi
                fi
 
                # If not provided default value neither passed a value, give an error
                #[[ "${var_required}" == "true" ]] && reworkedCode="${reworkedCode} [ \"\${${arg_index}}\" ] || exitOnError \"Values for argument '${var_name}' (index ${arg_index}) not found!\";"

                # If it is the rest, shift the past values
                if [[ "${var_rest}" == "true" ]]; then
                    ((arg_index-=1))
                    reworkedCode="${reworkedCode} shift ${arg_index} && local ${var_name}=${var_value};"
                    break
                else
                    reworkedCode="${reworkedCode} local ${var_name}=${var_value};"
                fi

                # Go to the next argument index
                ((arg_index+=1))
            done

            # Add the validation
            reworkedCode="[ \${#@} -ge ${arg_expected} ] || exitOnError \"Invalid arguments at '\${BASH_SOURCE[-1]}' (Line \${BASH_LINENO[-2]}), values expected: ${arg_expected} - received: \${#@}\nUsage: '${_newFunc} ${var_names[@]}'\"; ${reworkedCode}"

            # Update the code
            _body=${_body/"${lineFound}"/"${reworkedCode}"}
        fi
    done

    ############## Header ##############
    # Add to the function the lib context
    _body="local SELF_LIB='${_lib}'; local SELF_LIB_DIR='${_libDir}';${_body}"
    ############## Header ##############
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
