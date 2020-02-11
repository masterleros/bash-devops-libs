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

####### TEST PREPARATION #######
TESTS_DIR="tests"
export DOLIBS_LOCAL_MODE_DIR="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd)"
CURRENT_DIR="$(cd $(dirname ${BASH_SOURCE[0]}) >/dev/null 2>&1 && pwd)"
####### TEST PREPARATION #######

### Print a nice title ###
# usage: _showTestTitle "text"
function _showTestTitle {
    local _len=$(echo "- ${1} -"| wc -c)
    separator=$(eval printf '\=%.0s' {2..${_len}}})
    echo ${separator}
    echo "- ${1} -"
    echo ${separator}
}

### Run the test
function runTest() {

    local _testPath=${1}
    local _bashArgs=${2}
    local _bashArgsText=$([ ! "${_bashArgs}" ] || echo " (Args: ${_bashArgs})")
    
    _showTestTitle " START TEST $(basename ${_testPath})${_bashArgsText} "

    # grant execution permissions
    chmod +x ${_testPath}

    # Execute the test
    if [ "${_bashArgs}" ]; then bash -c "${_bashArgs}; ${_testPath}"
    else bash -c "${_testPath}"; fi
    
    # If test has failed
    if [ ${?} -ne 0 ]; then 
        _showTestTitle " TEST FAILED $(basename ${_testPath})${_bashArgsText} "
        exit -1; 
    fi    

    _showTestTitle " TEST SUCCESS $(basename ${_testPath})${_bashArgsText} "  
}

# Get tests and execute them
_testsFiles=($(find ${CURRENT_DIR}/${TESTS_DIR} -name test-*.sh))
_testsSuccess=0
for _testFile in "${_testsFiles[@]}"; do    
    runTest "${_testFile}" ""    
    echo
    runTest "${_testFile}" "set -e"
    echo
    ((_testsSuccess+=1))
done

echo "SUCCESS Tests: ${_testsSuccess}"
