* [utils.files.findAndCallback()](#utilsfilesfindandcallback)
* [utils.showTitle()](#utilsshowtitle)
* [utils.retryExecution()](#utilsretryexecution)
* [utils.tokens.get()](#utilstokensget)
* [utils.tokens.getNames()](#utilstokensgetnames)
* [utils.tokens.replaceFromFile()](#utilstokensreplacefromfile)
* [utils.tokens.replaceFromFileToFile()](#utilstokensreplacefromfiletofile)






# utils.files.findAndCallback()

Find all files in a folder and execute a callback function for each

### Arguments

* **dir** (path): Path to dir to look for files with the specified name
* **file** (string): File to look for
* **callback** (function): Function name to be called when file is found (will receive 1st argument the found file path)
* **args** (args): Optional arguments to be passed to the callback function

### Exit codes

* **0**: Files found and all the callback functions reported exitcode=0
* **1**: Files where not found

### Example

```bash
findAndCallback <dir> <file> <callback> [args]
```




# utils.showTitle()

Print a nice title

### Arguments

* **text** (text): Titles's text

# utils.retryExecution()

Execute a command until success within a retries

### Arguments

* $retries number ammount of retries
* $cmd string command to be executed




# utils.tokens.get()

Echo the tokens found in a text (i.e: `${<token>}`)

### Arguments

* **data** (string): Data where the tokens are expected

### Example

```bash
get <data>
```

# utils.tokens.getNames()

Echo the tokens names found in a text

### Arguments

* **data** (string): Data where the tokens are expected

### Example

```bash
getNames <data>
```

# utils.tokens.replaceFromFile()

Echo the content of a file with tokens updated to values from defined environment vars

### Arguments

* **file** (path): Path to file
* **errors** (bool): (optional) if specified (true) tokens not found will be reported and exitcode will be != 0

### Return value

* Content with token replaced

### Exit codes

* **0**: All token replaced
* **1**: Some tokens not found defined to be replaced (only with arg errors=true)

### Output on stderr

* Tokens not found (only with arg errors=true)

### Example

```bash
replaceFromFile <file> [errors]
```

# utils.tokens.replaceFromFileToFile()

Dump to a target file the content of a source file with tokens updated to values from defined environment vars

### Arguments

* **source** (path): Path to source file
* **target** (path): Path to target file
* **errors** (bool): (optional) if specified (true) tokens not found will be reported and exitcode will be != 0

### Exit codes

* **0**: All token replaced
* **1**: Some tokens not found defined to be replaced (only with arg errors=true)

### Output on stderr

* Tokens not found (only with arg errors=true)

### Example

```bash
replaceFromFileToFile <source> <target> [errors]
```

