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


# Required variables
declare -a _LIBTIME_TIMERS

# @description Set a named timer to calculate future elapsed seconds
# @arg $name string Timer's name
# @example
#   startTimer <name>
function startTimer() {
    getArgs "name" "${@}"
    _LIBTIME_TIMERS["${name}"]=${SECONDS}
}

# @description Get the elapsed seconds from a named timer
# @arg $name string Timer's name
# @return Seconds since the timer was set
# @example
#   elapsed <name>
function elapsed() {
    getArgs "name" "${@}"
    _return=$(( SECONDS - ${_LIBTIME_TIMERS["${name}"]} ))
}

# @description Create a human timing description from seconds
# @arg $seconds int Seconds
# @return Text with the time description
# @example
#   human <seconds>
function human() {
    getArgs "seconds" "${@}"

    # Separate the time units
    local shiff=${seconds}
    local secs=$((shiff % 60)); shiff=$((shiff / 60));
    local mins=$((shiff % 60)); shiff=$((shiff / 60));
    local hours=${shiff}

    # Prepare plurals
    local splur; if [ ${secs}  -eq 1 ]; then splur=''; else splur='s'; fi
    local mplur; if [ ${mins}  -eq 1 ]; then mplur=''; else mplur='s'; fi
    local hplur; if [ ${hours} -eq 1 ]; then hplur=''; else hplur='s'; fi

    # Create the text
    if [[ ${hours} -gt 0 ]]; then
        txt="${hours} hour${hplur}, ${mins} minute${mplur}, ${secs} second${splur}"
    elif [[ ${mins} -gt 0 ]]; then
        txt="${mins} minute${mplur}, ${secs} second${splur}"
    else
        txt="${secs} second${splur}"
    fi

    # Resturn result
     _return="${txt}"
} 
