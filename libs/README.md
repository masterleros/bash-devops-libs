# Library development rules

When you develop a new library, some steps should be followed:

1. Place your library on the `libs/<LIB_NAME>/main.sh` file. This will implicitly recognize the library "<LIB_NAME>lib", example:
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
    # Special chars: '$' = not mandatory / '@' = get rest of arguments    
    getArgs "arg1 arg2 $@other_args" ${@}
    ```
4. Use the function `exitOnError` to explicitly show an error if it happens (if not, nothing will be shown and the execution will continue)
    ``` sh
    ((1/0))
    exitOnError "It has happend a division by 0 error here!"
    ```
5. Include at the very end of you script the following instruction (this will export your functions when executing your script directly)
    ``` sh
    # Export internal functions
    eval "${useInternalFunctions}"
    ```
6. Document your library properly in the library folder and include a reference in this README.md file

### Implementation example:

**libs/myfuncs/main.sh**
``` sh
...
function doSomething() {
    getArgs "arg1 arg2 $@other_args" ${@}
    echo "Arg1 = ${arg1}"
    echo "Arg2 = ${arg2}"
    echo "Others = ${other_args[@]}"
    exitOnError "It was not possible to print properly the arguments =("
}
```

**Following the above definition, we can see:**
``` sh
...
importLibs myfuncslib
myfuncslib doSomething Hi There From GitLab Libs!

# Ourtput:
# Arg1 = Hi
# Arg1 = There
# Others = From GitLab Libs!
```    

# Library Catalog

## base.sh
This is the root level source and includes all the base functions to use the GitLab Libs (i.e: importLibs)
> **Obs:** This file will be automatically be imported by the gitlab-libs.sh execution.

## gcp
This library includes different functionalities for Google Cloud Platform

## utils
TODO

TODO