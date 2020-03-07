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

# Bash color options
# https://misc.flogisoft.com/bash/tip_colors_and_formatting

### Set current color
# usage: _addColorText <text>
function _addColorText() {
    _text="${_text}\e[${1}m${@}"
}

### Echo the required text
# usage: _echo <text>
function _echo() {
    local _stdRedirect="${1}"; shift
    local _textToPrint="${1}"; shift
    local _textToPrintColor="${1}"; shift
    local _text="${@/'\n'/$'\n'}"

    # For each line
    local IFS=$'\n'
    for _line in ${_text[@]}; do
        echo -e "\e[1m\e[${_textToPrintColor}m${_textToPrint} \e[0m${_line}" >&${_stdRedirect}
        _textToPrint="       "
    done
}

### Show debug information
# usage: echoDebug <text>
function echoDebug() {
    [ "${DOLIBS_DEBUG}" != "true" ] || _echo 1 "DEBUG: " 36 ${@}
}

### Show a info text
# usage: echoInfo <text>
function echoInfo() {
    _echo 1 "INFO:  " 32 "${@}"
}

### Show a warning text
# usage: echoWarn <text>
function echoWarn() {
    _echo 1 "WARN:  " 33 ${@}
}

### Show an error text (stderr)
# usage: echoError <text>
function echoError() {
    _echo 2 "ERROR: " 31 "${@}"
}

### Show a tittle
# usage: echoError <text>
function echoTittle() {
    echo
    echo -e "\e[1m        ${@}"
    echo
}