 
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

### Find all files in a folder and execute a callback function ###
# usage: findAndCallback <absolute_root_folder_path> <filename> <callback_function>
function findAndCallback() {
    getArgs "path file callback &@args" "${@}"

    filesFound=($(find ${path} -iname ${file} | sort))
    [ "${#filesFound[@]}" -eq 0 ] && exitOnError "Unable to locate any '${file}' file." -1

    for fileFound in ${filesFound[@]}; do
        ${callback} ${fileFound} "${args[@]}"
    done
}
