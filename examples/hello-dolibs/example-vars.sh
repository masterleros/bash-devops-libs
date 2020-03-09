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

# Enable dolibs (offline)
source $(dirname "${BASH_SOURCE[0]}")/../../dolibs.sh --offline --debug

# Define a custom function
function myOwnFunction() {
    
    getArgs "var1 var2 @array" "${@}"

    # Show the values received    
    echoInfo "var1 value is '${var1}'"
    echoInfo "var2 value is '${var2}'"
    echoInfo "array values are '${array[@]}'"

    # This will return a value
    _return="This is the function result and received var1='${1}'!"

    # This will set the exit code
    return 0
}

# Execute my function with the required values
assign myVar=myOwnFunction first second 3 fourth 5

# Show the value and exit code that was returned
echoInfo "myOwnFunction() exit code was: '${?}', value returned is: '${myVar}'"