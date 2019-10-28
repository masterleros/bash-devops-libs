# Library Development

## Rules
When you develop a new library, some steps should be followed:

### Inside your global script code:
1. Place your library as `libs/<LIB_NAME>/main.sh` file. This will implicitly recognize the library "<LIB_NAME>lib", example:
> **Info:**  `CURRENT_LIB` (your own library name) and `CURRENT_LIB_PATH` (your library path) variables will be already defined for your usage.

2. Verify the required dependencies for your execution, example:
    ``` sh
    # Validate available variables (if applicable) and return if error
    validateVars <var1> <var2> ... <varN> || return ${?}

    # Verify Dependencies (if applicable) and return if error
    verifyDeps <dep1> <dep2> ... <depN> || return ${?}
    ```

3. Include your sub-modules:
    Use the `importSubModules` function to import sub-modules (scripts within your lib dir), example:
    ``` sh
    # This will import files iam.sh, api.sh and auth.sh placed on same folder as main.sh file
    importSubModules iam api auth    
    ```

### Inside your functions:
5. Use the function `getArgs` to validate the passed arguments (Check documentation in `base.sh` file):
    ``` sh    
    # Validate and get the required arguments
    # Special chars: '&' = not mandatory / '@' = get rest of arguments    
    getArgs "arg1 arg2 &@other_args" ${@}
    ```
6. Use the function `exitOnError` to explicitly show an error if it happens (if not, nothing will be shown and the execution will continue)
    ``` sh
    ((1/0))
    exitOnError "It has happend a division by 0 error here!"
    ```
7. Document your library properly in the library folder and include a reference in this README.md file

## Self Functions

To use functions inside same lib, call them by using: `self <function_name>`. By doing this, your function will called properly as `<lib>.<function>` so you can use it internally in within your code. example:

**libs/myfunc/main.sh**
``` sh
#!/bin/bash

function my_other_function() { 
    echoInfo "Hi from my other function!" 
}

function my_function() 
{ 
    echoInfo "Hi from my function!" 
    self my_other_function
}
```

**test.sh**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh
importLibs myfunc
myfunclib.my_public_function

# Output:
# Hi from my function!
# Hi from my other function!
```

## Implementation example:

**libs/myfuncs/main.sh**
``` sh
#!/bin/bash

# Validate Variables
validateVars example_var || return ${?}

# Verify Dependencies
verifyDeps example_dep || return ${?}

# Import sub-modules
importSubModules sub-module1 sub-module2

# Declare your functions
function doSomething() {
    getArgs "arg1 arg2 &@other_args" ${@}
    echoInfo "Arg1 = ${arg1}"
    echoInfo "Arg2 = ${arg2}"
    echoInfo "Others = ${other_args[@]}"
    exitOnError "It was not possible to print properly the arguments =("
}
```

**Following the above definition, we can see:**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh
importLibs myfuncslib
myfuncslib.doSomething Hi There From DevOps Libs!

# Output:
# Arg1 = Hi
# Arg1 = There
# Others = From DevOps Libs!
```    

# Library Catalog

## base.sh
This is the root level source and includes all the base functions to use the DevOps Libs (i.e: importLibs)
> **Obs:** This file will be automatically be imported by the devops-libs.sh execution.

## gcp
This library includes different functionalities for Google Cloud Platform

## utils
TODO

TODO