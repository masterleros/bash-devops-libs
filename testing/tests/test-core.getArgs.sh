#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/devops-libs.sh

### YOUR CODE ###

echoInfo "getArgs Normal"
getArgs "a b c" 1 2 3
[[ "${a} ${b} ${c}" == "1 2 3" ]] || exit -1

echoInfo "getArgs Default=1"
getArgs "a b c=456" 1 2
[[ "${a} ${b} ${c}" == "1 2 456" ]] || exit -1

getArgs "a b c=456 d=876" 1 2
[[ "${a} ${b} ${c} ${d}" == "1 2 456 876" ]] || exit -1

getArgs "a b c=3 d=4" 1 2 1234 5678
[[ "${a} ${b} ${c} ${d}" == "1 2 1234 5678" ]] || exit -1

getArgs "a b c=3 d=4" 1 2 5
[[ "${a} ${b} ${c} ${d}" == "1 2 5 4" ]] || exit -1

echoInfo "getArgs &Optional"
getArgs "a b &c" 1 2 3
[[ "${a} ${b} ${c}" == "1 2 3" ]] || exit -1

getArgs "a b &c" 1 2
[[ "${a} ${b} ${c}" == "1 2 " ]] || exit -1

echoInfo "getArgs @Rest"
getArgs "a @b" 1 2 3
[[ "${a} ${b[0]} ${b[1]}" == "1 2 3" ]] || exit -1

### YOUR CODE ###
