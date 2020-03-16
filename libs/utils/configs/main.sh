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

# @description Get values from file's variables and set into same given variable names
# @arg $file path Path to the file
# @arg $args list Variables names to be set
# @exitcode 1 File not found
# @example 
#   setVariablesFromFile <file> <var1> <var2> ... <varN>
function setVariablesFromFile() {
     getArgs "file @vars"

     [ -f "${file}" ] || exitOnError "File '${file}' not found" -1

     # For each var
     for _var in ${vars[@]}; do
          local _temp=$(< "${file}" grep "${_var}" | awk -F "=" '{print $2}' | tr -d '"' | tr -d ' ')
          [ "${_temp}" ] || exitOnError "Value ${_var} is undefined! check ${file} file" -1
          echoInfo "Setting ${_var} = '${_temp}'"
          eval $(echo "${_var}"="'${_temp}'")
     done
}
