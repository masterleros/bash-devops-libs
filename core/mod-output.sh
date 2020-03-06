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

### Show a info text
# usage: echoInfo <text>
function echoInfo() {
    local IFS=$'\n'
    local _text="${1/'\n'/$'\n'}"
    local _lines=(${_text})
    local _textToPrint="INFO:  "
    for _line in "${_lines[@]}"; do
        echo "${_textToPrint} ${_line}"
        _textToPrint="       "
    done
}

### Show a test in the stderr
# usage: echoError <text>
function echoError() {
    local IFS=$'\n'
    local _text="${1/'\n'/$'\n'}"
    local _lines=(${_text})
    local _textToPrint="ERROR: "
    for _line in "${_lines[@]}"; do
        echo "${_textToPrint} ${_line}" >&2
        _textToPrint="       "
    done
}
