* [utils.array.valueInArray()](#utilsarrayvalueinarray)
* [utils.configs.setVariablesFromFile()](#utilsconfigssetvariablesfromfile)
* [utils.files.findAndCallback()](#utilsfilesfindandcallback)
* [utils.retryExecution()](#utilsretryexecution)
* [utils.tokens.get()](#utilstokensget)
* [utils.tokens.getNames()](#utilstokensgetnames)
* [utils.tokens.replaceFromFile()](#utilstokensreplacefromfile)
* [utils.tokens.replaceFromFileToFile()](#utilstokensreplacefromfiletofile)



# utils.array.valueInArray()

Check if a value exists in an array

### Arguments

* **value** (value): Value to look for
* **array** (array): Array to look for the value

### Return value

* Found value position

### Exit codes

* **0**: Value was found
* **1**: Value not found

### Example

```bash
assign valPos=valueInArray <value> <array>
```




# utils.configs.setVariablesFromFile()

Get values from file's variables and set into same given variable names

### Arguments

* **file** (path): Path to the file
* **args** (list): Variables names to be set

### Exit codes

* **1**: File not found

### Example

```bash
setVariablesFromFile <file> <var1> <var2> ... <varN>
```




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




# utils.retryExecution()

Execute a command until success within a retries

### Arguments

* **retries** (number): ammount of retries
* **cmd** (string): command to be executed




# utils.tokens.get()

Echo the tokens found in a text (i.e: `${<token>}`)

### Arguments

* **data** (string): Data where the tokens are expected

### Return value

* Array with the tokens found

### Example

```bash
get <data>
# output:
"${token1}" "${token2}" "${tokenN}"
```

# utils.tokens.getNames()

Echo the tokens names found in a text

### Arguments

* **data** (string): Data where the tokens are expected

### Return value

* Array with the token's names found

### Example

```bash
getNames <data>
# output:
"token1" "token2" "tokenN"
```

# utils.tokens.replaceFromFile()

Echo the content of a file with tokens updated to values from defined environment vars

### Arguments

* **file** (path): Path to file

### Return value

* Content with token replaced

### Exit codes

* **0**: All token replaced
* **>0**: Count of tokens not found to be replaced

### Example

```bash
replaceFromFile <file>
```

# utils.tokens.replaceFromFileToFile()

Dump to a target file the content of a source file with tokens updated to values from defined environment vars

### Arguments

* **source** (path): Path to source file
* **target** (path): Path to target file

### Exit codes

* **0**: All token replaced
* **>0**: Count of tokens not found to be replaced

### Example

```bash
replaceFromFileToFile <source> <target>
```

