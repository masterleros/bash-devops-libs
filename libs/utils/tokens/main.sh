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


# @description Echo the tokens found in a text (i.e: `${<token>}`)
# @arg data string Data where the tokens are expected
# @return Array with the tokens found
# @example 
#   get <data>
#   # output:
#   "${token1}" "${token2}" "${tokenN}"
function get() {

    getArgs "@data" "${@}"

    # Get tokens
    _return=($(echo "${data}" | egrep -o '\$\{([a-zA-Z0-9_]+)\}'))

    # Sort and make tokens unique in the list
    _return=($(echo "${_return[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
}

# @description Echo the tokens names found in a text
# @arg data string Data where the tokens are expected
# @return Array with the token's names found
# @example 
#   getNames <data>
#   # output:
#   "token1" "token2" "tokenN"
function getNames() {

    getArgs "@data" "${@}"

    # Get the tokens
    assign _return=self get "${data}"

    # Remove token structure chars
    _return=(${_return[@]/\${/})
    _return=(${_return[@]/\}/})
}

# @description Echo the content of a file with tokens updated to values from defined environment vars
# @arg file path Path to file
# @arg errors bool (optional) if specified (true) tokens not found will be reported and exitcode will be != 0
# @return Content with token replaced
# @exitcode 0 All token replaced
# @exitcode 1 Some tokens not found defined to be replaced (only with arg errors=true)
# @stderr Tokens not found (only with arg errors=true)
# @example 
#   replaceFromFile <file> [errors]
function replaceFromFile() {

    getArgs "file &errors" "${@}"

    # Check if file exists
    [ -f "${file}" ] || exitOnError "File '${file}' not found"
    local _content=$(cat "${file}")

    # Get the tokens
    assign tokens=self get "${_content}"

    # Replace each var if exists
    local _result=0
    for token in ${tokens[@]}; do
        # If variable is defined, replace
        var=$(echo "${token}" | egrep -o '([a-zA-Z0-9_]+)')
        if [ "${!var}" ]; then
            _content=${_content//$token/${!var}}
        else
            if [[ "${errors}" == "true" ]]; then echoError "Variable '${var}' is not defined!"; fi
            ((_result+=1))
        fi
    done

    _return=${_content}
    return ${_result}
}

# @description Dump to a target file the content of a source file with tokens updated to values from defined environment vars
# @arg source path Path to source file
# @arg target path Path to target file
# @arg errors bool (optional) if specified (true) tokens not found will be reported and exitcode will be != 0
# @exitcode 0 All token replaced
# @exitcode 1 Some tokens not found defined to be replaced (only with arg errors=true)
# @stderr Tokens not found (only with arg errors=true)
# @example 
#   replaceFromFileToFile <source> <target> [errors]
function replaceFromFileToFile() {

    getArgs "path_source path_target &errors" "${@}"

    # Get the content updated
    assign content=self replaceFromFile "${path_source}" "${errors}"
    local _result=${?}

    echo "${content}" > "${path_target}"   
    return ${_result}
}
