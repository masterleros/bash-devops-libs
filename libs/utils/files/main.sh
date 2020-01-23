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
