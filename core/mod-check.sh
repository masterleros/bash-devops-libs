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

# @description Validate if the specified variables are defined
# @arg $@ list variables names to be validated
# @exitcode 0 If all are defined
# @exitcode >0 Amount of variables not defined
# @stdout Variables not declared
# @example 
#   checkVars <var1> <var2> ... <varN>
function checkVars() {
    local _result=0
    for var in ${@}; do
        if [ -z "${!var}" ]; then
            echoWarn "Environment varirable '${var}' is not declared!"
            ((_result+=1))
        fi
    done
    return ${_result}
}

# @description Verify if the specified binaries dependencies are available
# @arg $@ list binaries to be verified
# @exitcode 0 If all are found
# @exitcode >0 Amount of binaries not found
# @stderr Binaries not found
# @example 
#   checkBins <bin1> <bin2> ... <binN>
function checkBins() {
    local _result=0
    for dep in ${@}; do
        which "${dep}" &> /dev/null
        if [[ $? -ne 0 ]]; then
            echoWarn "Binary dependency '${dep}' not found!"
            ((_result+=1))
        fi
    done
    return ${_result}
}