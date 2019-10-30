# Library Development

## Rules
When you develop a new library, some steps should be followed:

### Inside your global script code:
1. Place your library as `libs/<LIB_NAME>/main.sh` file. This will implicitly recognize the library "<LIB_NAME>lib", example:
> **Info:**  `CURRENT_LIB` (your own library name) and `CURRENT_LIB_DIR` (your library base dir) variables will be already defined for your usage.

2. Verify the required dependencies for your execution, example:
    ``` sh
    # Validate available variables (if applicable) and return if error
    validateVars <var1> <var2> ... <varN> || return ${?}

    # Verify Dependencies (if applicable) and return if error
    verifyDeps <dep1> <dep2> ... <depN> || return ${?}
    ```

3. Include your files:
    Use the `source` to incorporate to your lib other scripts (within your lib dir), example:
    ``` sh
    # This will add the code from additional_functions.sh 
    # and other_functions.sh files inside your lib folder
    source ${CURRENT_LIB_DIR}/additional_functions.sh || return ${?}
    source ${CURRENT_LIB_DIR}/other_functions.sh || return ${?}
    ```

4. Include other libraries:
    Use the `do.import` function to import other libraries for your library, example:
    ``` sh
    # This will import the utils library
    do.import utils

    # Then You can access the library from your functions
    function myTest() {
        do.utils.showTitle "This is a test!"
    }
    ```
5. Document your library properly in the library folder and include a reference in this README.md file    

### Inside your functions:

- Use the function `getArgs` to validate the passed arguments (Check documentation in `core.sh` file):
    ``` sh    
    # Validate and get the required arguments
    # Special chars: '&' = not mandatory / '@' = get rest of arguments    
    getArgs "arg1 arg2 &@other_args" "${@}"

    echo ${arg1} # This will print first argume passed
    ```
- Use the function `exitOnError` to explicitly show an error if it happens (if not, nothing will be shown and the execution will continue)
    ``` sh
    ((1/0))
    exitOnError "It has happend a division by 0 error here!"
    ```
- Use `assign <var>=<function> <args>` in addition to `_return=<value>` inside the called function to return values from functions, example:
    ``` sh    
    function myFunction() {
        getArgs "text" "${@}"
        _return="Hello ${text}"
    }

    assign myVar=myFunction "my name!"
    echo ${myVar}

    # This will print "Hello my name"
    ```

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
do.import myfunc
do.myfunc.my_public_function

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
source ${CURRENT_LIB_DIR}/additional_functions.sh || return ${?}

# Import other required libs
do.import utils

# Declare your functions
function doOtherThing() {
    _return=${CURRENT_LIB_DIR}
}

function doSomething() {
    getArgs "arg1 arg2 &@other_args" "${@}"
    assign myLibDir=self doOtherThing
    echoInfo "Arg1 = ${arg1}"
    echoInfo "Arg2 = ${arg2}"
    echoInfo "Others = ${other_args[@]}"
    echoInfo "My dir is: ${myLibDir}"
    exitOnError "It was not possible to print properly the arguments =("
}
```

**Following the above definition, we can see:**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh
do.import myfuncslib
do.myfuncs.doSomething Hi There From DevOps Libs!

# Output:
# Arg1 = Hi
# Arg1 = There
# Others = From DevOps Libs!
# My path is: <lib path>
```    

# Library Catalog

## core.sh
This is the root level source and includes all the Core functions to use the DevOps Libs (i.e: do.import)
> **Obs:** This file will be automatically be imported by the devops-libs.sh execution.

## gcp
This library includes different functionalities for Google Cloud Platform

## utils
TODO

TODO