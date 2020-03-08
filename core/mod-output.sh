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

### Echo the required text
# usage: _echo <text>
function _echo() {

    local _stdRedirect="${1}"; shift
    local _textToPrint="${1}"; shift
    local _text="${@/'\n'/$'\n'}"

    # For each line
    local IFS=$'\n'
    for _line in ${_text[@]}; do
        echo -e "${_textToPrint} ${_line}" >&"${_stdRedirect}"
        _textToPrint="       "
    done
}

### Show a title
# usage: echoError <text>
function echoTitle() {
    echo
    _echo 1 "" "\e[1m       ${@}"
    echo
}

# Initiated on boostrap
# function echoDebug() { [ "${DOLIBS_DEBUG}" != "true" ] || _echo 1 "\e[1m\e[36mDEBUG: \e[0m" "${@}"; }
# function echoInfo()  { _echo 1 "\e[1m\e[32mINFO:  \e[0m ${@}"; }
# function echoWarn()  { _echo 1 "\e[1m\e[33mWARN:  \e[0m" "${@}"; }
# function echoError() { _echo 2 "\e[1m\e[31mERROR: \e[0m" "${@}"; }