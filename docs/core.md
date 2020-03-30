* [dolibReworkFunction()](#dolibreworkfunction)
* [dolibImportLib()](#dolibimportlib)
* [self()](#self)
* [assign()](#assign)
* [getArgs()](#getargs)
* [checkVars()](#checkvars)
* [checkBins()](#checkbins)
* [returnOnError()](#returnonerror)
* [exitOnError()](#exitonerror)
* [try()](#try)
* [echoTitle()](#echotitle)
* [echoDebug()](#echodebug)
* [echoInfo()](#echoinfo)
* [echoWarn()](#echowarn)
* [echoError()](#echoerror)
* [logToFile()](#logtofile)



# dolibReworkFunction()

Rework a function to enable dolibs features

### Arguments

* **func** (string): Current function name
* **newFunc** (string): (optional) New function name in case of renaming

### Example

```bash
dolibReworkFunction <func> <newFunc>
```

# dolibImportLib()

Import a library (this function is not intended to be used manually, instead use do.use or do.import)

### Arguments

* **lib** (string): Library namespace
* **libEntryPoint** (path): Path to lib entrypoint sh file

### Example

```bash
dolibImportLib <lib> <libEntryPoint>
```







# self()

Execute a function within same library module

### Exit codes

* **any**: passed command execution exit code

### Example

```bash
self <function> <args>
```

# assign()

Assign the returned value to a variable
  > Obs: your function needs to return values on the global `_return` variable

### Arguments

* **...** (list): variable=command and args

### Exit codes

* **any**: passed command execution exit code

### Example

```bash
function myFunc()
{
    _return="value"
}
assign var=myFunc <args>
echo ${var} # this will print 'value'
```

# getArgs()

Process the passed values in the required variables \
- A variable starting with `@`<var> will take the rest of values \
- A variable ending with <var>`=` is optional and script will not fail case there is no value for it
- A variable having equal plus value, as <var>`=`<default-value> is optional and will use default value when argument is not provided

### Example

```bash
# If any of the arguments is not provided, it will fail
getArgs "var1 va2 ... <varN>"
echo ${var1} # will print what was passed in ${1}
echo ${var2} # will print what was passed in ${2}
# Same for the rest of arguments
```

### Example

```bash
# var2 will be an array and will take all the remaining arguments 
getArgs "var1 @var2"
echo ${var1} # will print what was passed in ${1}
echo ${var2[@]} # will print all the rest of passed values
```

### Example

```bash
# var2 is optional and if not passed will print nothing
getArgs "var1 var2=[default] var3="
echo ${var1} # will print what was passed in ${1}
echo ${var2} # optional with a default value
echo ${var3} # optional with defaults as empty
```




# checkVars()

Validate if the specified variables are defined

### Arguments

* **...** (list): variables names to be validated

### Exit codes

* **0**: If all are defined
* **>0**: Amount of variables not defined

### Output on stdout

* Variables not declared

### Example

```bash
checkVars <var1> <var2> ... <varN>
```

# checkBins()

Verify if the specified binaries dependencies are available

### Arguments

* **...** (list): binaries to be verified

### Exit codes

* **0**: If all are found
* **>0**: Amount of binaries not found

### Output on stderr

* Binaries not found

### Example

```bash
checkBins <bin1> <bin2> ... <binN>
```




# returnOnError()

If the last command was not success, it will return the function with the last command exit code

### Exit codes

* **last**: Last execution exit code

# exitOnError()

If the last command was not success, it will exit the program with the last command exit code

### Arguments

* **message** (string): Message to be shown if the command failed
* **code** (integer): (optional) provide the exit code instead of use last command exit code

### Exit codes

* **last**: Last execution exit code

### Example

```bash
exitOnError <output_message> <exit_code>
```







# try()

Try execution in a subshel so that will not exit the program in case of failure

### Arguments

* **...** (list): Command to be executed

### Exit codes

* **last**: Last execution exit code

### Example

```bash
try <command>
```




# echoTitle()

Show a title

### Arguments

* **...** (string): Tittle's text

### Example

```bash
echoTitle <text>
```

# echoDebug()

Show a debug message (will print only when --debug flag is used)

### Arguments

* **...** (string): Text to be printed

# echoInfo()

Show an informative message

### Arguments

* **...** (string): Text to be printed

# echoWarn()

Show a warning message

### Arguments

* **...** (string): Text to be printed

# echoError()

Show an error message, this will be printed to the `stderr`

### Arguments

* **...** (string): Text to be printed

# logToFile()

Execute a command redirecting the output to a file

### Arguments

* **file** (path): Path to the output file
* **...** (list): Command to be executed

