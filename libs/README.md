# Library Development

## Rules
When you develop a new library, some steps should be followed:

1. Place your library on the `libs/<LIB_NAME>/main.sh` file. This will implicitly recognize the library "<LIB_NAME>lib", example:
> **Info:** `CURRENT_LIB_DIR` (your library relative path), `CURRENT_LIB_PATH` (your library path) and `CURRENT_LIB_NAME` (your own library name) variables will be defined in this execution.

2. Verify the required dependencies for your execution, example:
    ``` sh
    # Validate available variables (if applicable)
    validateVars <var1> <var2> ... <varN>

    # Verify Dependencies (if applicable)
    verifyDeps <dep1> <dep2> ... <depN>
    ```
3. Use the function `getArgs` to validate the passed arguments (Check documentation in `base.sh` file):
    ``` sh    
    # Validate and get the required arguments
    # Special chars: '&' = not mandatory / '@' = get rest of arguments    
    getArgs "arg1 arg2 &@other_args" ${@}
    ```
4. Use the function `exitOnError` to explicitly show an error if it happens (if not, nothing will be shown and the execution will continue)
    ``` sh
    ((1/0))
    exitOnError "It has happend a division by 0 error here!"
    ```
5. Document your library properly in the library folder and include a reference in this README.md file

## Sub Modules

Use the `importSubModules` function to import sub-modules, example:
``` sh
# Import sub-modules
importSubModules gae.sh iam.sh api.sh auth.sh
```

## Private Functions

To implement private functions, define them as `_<function_name>`. By doing this, your function will not be exposed as <lib>.<function> so you can use it internally in within your code. example:

**libs/myfunc/main.sh**
``` sh
#!/bin/bash

function _my_private_function() { 
    echoInfo "Hi from my private function!" 
}

function my_public_function() 
{ 
    echoInfo "Hi from my public function!" 
    _my_private_function
}
```

**test.sh**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh
importLibs myfunc
myfunc.my_public_function
# myfunc._my_private_function <-- does not exist!

# Output:
# Hi from my public function!
# Hi from my private function!
```

## Implementation example:

**libs/myfuncs/main.sh**
``` sh
#!/bin/bash

# Validate Variables
validateVars example_var

# Verify Dependencies
verifyDeps example_dep

# Import sub-modules
source ${CURRENT_DIR}/sub-module1.sh &&
source ${CURRENT_DIR}/sub-module2.sh
exitOnError "Error importing sub-modules"

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