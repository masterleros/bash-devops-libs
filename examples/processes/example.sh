#!/bin/bash
# Enable dolibs (use from ../../libs)
source $(dirname "${BASH_SOURCE[0]}")/../../dolibs.sh --offline

# Import the required lib
do.use process

# This function will be executed when waiting the subprocess and it fails
function endCallback() {
    getArgs "_code _pid _cmd _logFile" "${@}"

    # Depending on the exit code
    if [ "${_code}" == 0 ]; then
        echoInfo "Command '${_cmd}' completed successfully!"
    else
        echoError "Command '${_cmd}' failed with code '${_pid}', check logs at '${_logFile}'"
    fi
}

# for this execution we want the PID
assign pid=process.executeWithInfo "My failing command" /tmp/1.out ls i-dont-exist
echoInfo "PID required is '${pid}'"

# not PIDs needed for below
process.executeWithInfo "Just sleep 1s" /tmp/2.out sleep 1
process.executeWithInfo "Do some and sleep 3s" /tmp/3.out 'echo "doing something"; sleep 3; echo "I am done!"'
process.executeWithInfo "Print my root folder content" /tmp/4.out ls -l /
process.executeWithInfo "Just sleep 2s" /tmp/5.out sleep 2

# Wait all processes to end in within 20s
echoInfo "Waiting all commands to terminate..."
process.waitAll endCallback 8
exitOnError "Some processes failed"