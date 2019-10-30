#!/bin/bash

### This function will echo the tokens found in a file ###
# usage: get <data>
function get {

    getArgs "@data" "${@}"

    # Get tokens
    _return=($(echo ${data} | egrep -o '\$\{([a-zA-Z0-9_]+)\}'))

    # Sort and make tokens unique in the list
    _return=($(echo "${_return[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
}

### This function will echo the tokens names found in a file ###
# usage: getNames <data>
function getNames {

    getArgs "@data" "${@}"

    # Get the tokens
    assign _return=self get "${data}"

    # Remove token structure chars
    _return=("${_return[@]//'${'/}")
    _return=("${_return[@]//'}'/}")
}

### This function will echo the content of a file with tokens updated to values ###
# usage: replaceFromFile <path_to_file> [errors<true>]
function replaceFromFile {

    getArgs "file &errors" "${@}"

    # Check if file exists
    [ -f ${file} ] || exitOnError "File '${file}' not found"
    local _content=$(cat ${file})    

    # Get the tokens
    assign tokens=self get "${_content}"

    # Replace each var if exists
    local _result=0
    for token in ${tokens[@]}; do
        # If variable is defined, replace
        var=$(echo ${token} | egrep -o '([a-zA-Z0-9_]+)')
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

### This function will replace from a file to file
# usage: replaceFromFileToFile <path_source> <path_target> [errors<true>]
function replaceFromFileToFile {

    getArgs "path_source path_target &errors" "${@}"

    # Get the content updated
    assign content=self replaceFromFile ${path_source} ${errors}
    local _result=${?}

    echo "${content}" > ${path_target}    
    return ${_result}
}