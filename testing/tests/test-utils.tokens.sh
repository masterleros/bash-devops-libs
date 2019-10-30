#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/devops-libs.sh

# Import required libs
do.import utils.tokens # add your required libs

### YOUR CODE ###
assign tokens=do.utils.tokens.getNames '${a} ${b} ${c}'
[[ "${tokens[@]}" == "a b c" ]] || exit -1
### YOUR CODE ###
