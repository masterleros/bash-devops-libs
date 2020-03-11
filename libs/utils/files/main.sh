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

# @description Find all files in a folder and execute a callback function for each
# @arg $dir path Path to dir to look for files with the specified name
# @arg $file string File to look for
# @arg $callback function Function name to be called when file is found (will receive 1st argument the found file path)
# @arg $args args Optional arguments to be passed to the callback function
# @exitcode 0 Files found and all the callback functions reported exitcode=0
# @exitcode 1 Files where not found
# @example 
#   findAndCallback <dir> <file> <callback> [args]
function findAndCallback() {
    getArgs "path file callback @args="

    filesFound=($(find "${path}" -iname "${file}" | sort))    
    [ "${#filesFound[@]}" -eq 0 ] && exitOnError "Unable to locate any '${file}' file." -1

    for fileFound in ${filesFound[@]}; do
        "${callback}" "${fileFound}" "${args[@]}"
    done
}
