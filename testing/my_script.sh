#!/bin/bash

####### TEST PREPARATION #######
CURRENT_DIR="$(cd $(dirname ${BASH_SOURCE[0]}) >/dev/null 2>&1 && pwd)"
DEVOPS_LIBS_LOCAL_MODE_PATH="$(cd $(dirname ${BASH_SOURCE[0]})/../ >/dev/null 2>&1 && pwd)"
cp ${DEVOPS_LIBS_LOCAL_MODE_PATH}/devops-libs.sh ${CURRENT_DIR}/devops-libs.sh
####### TEST PREPARATION #######

# Start the library
source $(dirname ${BASH_SOURCE[0]})/devops-libs.sh online

# Import required libs
importLibs utils # add your required libs

### YOUR CODE ###

utilslib.showTitle "Hello World!"

### YOUR CODE ###
