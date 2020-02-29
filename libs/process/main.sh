#!/bin/bash

# Verify Dependencies
verifyDeps ps tr egrep || return ${?}

# Required variables
_LIBPROC_PIDS=""
declare -a _LIBPROC_CMDS
declare -a _LIBPROC_LOG_FILES

# @description Execute in a subprocess and redirect its outputs to the logfile
# @arg $outfile path Path to file where the outputs are redirected
# @arg $command string Command to be executed
# @example
#   execute <outfile> <command> <args>
function execute() {

    getArgs "_outfile @_command" "${@}"

    eval ${_command[@]} &>${_outfile} &
    _return=${!}

    # Store the command for future track
    _LIBPROC_CMDS[${_return}]="${_command[@]}"
    _LIBPROC_LOG_FILES[${_return}]="${_outfile}"

    # Add the pid in the executed list
    _LIBPROC_PIDS="${_LIBPROC_PIDS} ${!}"
}

# @description Execute in a subprocess and redirect its outputs to the logfile with a message
# @arg $info string Message to identy what was executed
# @arg $outfile path Path to file where the outputs are redirected
# @arg $command string Command to be executed
# @example
#   executeWithInfo <info> <outfile> <command> <args>
function executeWithInfo() {
    getArgs "_info _outfile @_command" "${@}"
    echoInfo "Executing '${_info}' (output at '${_outfile}')"
    self execute "${_outfile}" "${_command[@]}"    
    _return=${_return}
}

# @description Wait all executed processes with a timeout and an end callback function
# @arg $endCallbackFunc function Path to file where the outputs are redirected
# @arg $_command string Command to be executed
# @exitcode 0 If all processes ended with code 0
# @exitcode >0 If some process ended with error
# @exitcode 124 If some function ended because timeout
# @example 
#   waitAll <endCallbackFunc> <timeout>
function waitAll() {

    getArgs "_endCallbackFunc &_timeout" "${@}"

    local _result=0

    # Wait all processes in list
    if [ "${_timeout}" ]; then

        # Wait until all processes are ended or timed out        
        while [ "${_LIBPROC_PIDS}" ]; do

            ### Process already ended processes
            local TERM_PIDS=$(echo "${_LIBPROC_PIDS}" | tr " " "\n" | egrep -x -v "$(ps -o pid= -p ${_LIBPROC_PIDS} | tr "\n" "|")")

            # Get the exit status
            for DOLIB_PID in ${TERM_PIDS}; do
                wait ${DOLIB_PID}
                local _current=${?}

                # Remove terminated PIDS
                _LIBPROC_PIDS=$(echo "${_LIBPROC_PIDS}" | tr " " "\n" | egrep -x -v "${DOLIB_PID}")

                # Callback function
                "${_endCallbackFunc}" "${_current}" "${_current}" "${_LIBPROC_CMDS[${DOLIB_PID}]}" "${_LIBPROC_LOG_FILES[${DOLIB_PID}]}"

                # Set final status
                ((_result=${_result} | ${_current}))
            done

            ### If timed out, return ##
            ((_timeout--))
            if [ "${_timeout}" -lt 0 ]; then
                echoError "Timeout"
                return 124
            fi
            ###########################

            sleep 1
        done
    fi

    # return result
    return ${_result}
}