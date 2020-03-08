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

# Define global validations
checkVars I_DO_NOT_EXIST ME_NEITHER
checkBins invalid_binary other_inexistent_binary
# exitOnError can be used to exit if values where not found

# Define global function
function globalFunction() {
    echoInfo "Hello from '${FUNCNAME}()'"
}

# Define global function
export GLOBAL_VALUE="I'm a global value!"
