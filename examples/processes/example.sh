#!/bin/bash
# Enable dolibs (use from ../../libs)
source $(dirname "${BASH_SOURCE[0]}")/../../dolibs.sh --offline

# Import the required lib
do.use process time

# This function will be executed when waiting the subprocess and it fails
function endCallback() {
    getArgs "_code _pid _cmd _logFile _elapsed"

    # Depending on the exit code
    if [ "${_code}" == 0 ]; then
        echoInfo "Command '${_cmd}' completed successfully! (${_elapsed}s)"
    else
        echoError "Command '${_cmd}' failed with code '${_code}', check logs at '${_logFile}'"
    fi
}

# Set the timer
time.startTimer DEPLOY_TIMER

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
process.waitAll endCallback 10
waitResult=${?}

# Get the elapsed time
assign elapsed=time.elapsed DEPLOY_TIMER
assign human=time.human "${elapsed}"
echoInfo "Elapsed time: ${human}"

exitOnError "Some processes failed" ${waitResult}
