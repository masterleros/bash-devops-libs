#!/bin/bash

### Get values of variables from file and set them into the given variable names ###
# usage: getValuesFromFile <file> <var1> <var2> ... <varN>
function getValuesFromFile() {
     getArgs "file @vars" "${@}"

     [ -f ${file} ] || exitOnError "File '${file}' was not found" -1

     for _var in ${vars[@]}; do
          local _temp="$(cat ${file} | grep ${_var} | awk -F "=" '{print $2}' | tr -d '"' | tr -d ' ')"
          [ "${_temp}" ] || exitOnError "Value ${_var} is undefined! check ${file} file" -1
          echoInfo "Setting ${_var} = '${_temp}'"
          eval "$(echo ${_var}='${_temp}')"
     done
}