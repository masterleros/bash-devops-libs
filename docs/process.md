* [process.execute()](#processexecute)
* [process.executeWithInfo()](#processexecutewithinfo)
* [process.waitAll()](#processwaitall)



# process.execute()

Execute in a subprocess and redirect its outputs to the logfile

### Arguments

* $outfile path Path to file where the outputs are redirected
* $command string Command to be executed

### Example

```bash
execute <outfile> <command> <args>
```

# process.executeWithInfo()

Execute in a subprocess and redirect its outputs to the logfile with a message

### Arguments

* $info string Message to identy what was executed
* $outfile path Path to file where the outputs are redirected
* $command string Command to be executed

### Example

```bash
executeWithInfo <info> <outfile> <command> <args>
```

# process.waitAll()

Wait all executed processes with a timeout and an end callback function

### Arguments

* $endCallbackFunc function Path to file where the outputs are redirected
* $_command string Command to be executed

### Exit codes

* **0**: If all processes ended with code 0
* **>0**: If some process ended with error
* **124**: If some function ended because timeout

### Example

```bash
waitAll <endCallbackFunc> <timeout>
```

