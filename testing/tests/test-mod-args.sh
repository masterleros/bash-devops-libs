#!/bin/bash
source $(dirname "${BASH_SOURCE[0]}")/../../dolibs.sh --offline

### YOUR CODE ###
function testFailed() {
  echoError "MOD-ARGS TEST FAILED"
  exit -1
}

function runModArgsTest() {
  dolibReworkFunction ${1} "${1}_Reworked"
  "${1}_Reworked" 1 2 3
}

# Basic usage tests
echoInfo "Test getArgs Normal"
function runModArgsTest_1() {
  getArgs "a b c"
  [[ "${a} ${b} ${c}" == "1 2 3" ]] || testFailed
}
runModArgsTest runModArgsTest_1

echoInfo "Test getArgs Default=1"
function runModArgsTestDefault_1() {
  getArgs "a b c d=456"
  [[ "${a} ${b} ${c} ${d}" == "1 2 3 456" ]] || testFailed
}
runModArgsTest runModArgsTestDefault_1
echoInfo "Test getArgs Default=2"
function runModArgsTestDefault_2() {
  getArgs "a b c=456 d=876"
  [[ "${a} ${b} ${c} ${d}" == "1 2 3 876" ]] || testFailed
}
runModArgsTest runModArgsTestDefault_2

echoInfo "Test getArgs Default=3"
function runModArgsTestDefault_3() {
  getArgs "a b=5 c=6"
  [[ "${a} ${b} ${c}" == "1 2 3" ]] || testFailed
}
runModArgsTest runModArgsTestDefault_3

echoInfo "Test getArgs Default=4"
function runModArgsTestDefault_4() {
  getArgs "a b c=4 d=5"
  [[ "${a} ${b} ${c} ${d}" == "1 2 3 5" ]] || testFailed
}
runModArgsTest runModArgsTestDefault_4


echoInfo "Test getArgs Optional="
function runModArgsTestOptional_1() {
  getArgs "a b c= d="
  [[ "${a} ${b} ${c} ${d}" == "1 2 3 " ]] || testFailed
}
runModArgsTest runModArgsTestOptional_1

echoInfo "Test getArgs 2nd Optional="
function runModArgsTestOptional_2() {
  getArgs "a b c= d= e="
  [[ "${a} ${b} ${c} ${d} ${e}" == "1 2 3  " ]] || testFailed
}
runModArgsTest runModArgsTestOptional_2


echoInfo "Test getArgs @Rest"
function runModArgsTestRest_1() {
  getArgs "a @b"
  [[ "${a} ${b[0]} ${b[1]}" == "1 2 3" ]] || testFailed
}
runModArgsTest runModArgsTestRest_1

echoInfo "Test getArgs 2nd @Rest"
function runModArgsTestRest_2() {
  getArgs "@b"
  [[ "${b[0]} ${b[1]} ${b[2]}" == "1 2 3" ]] || testFailed
}
runModArgsTest runModArgsTestRest_2

echoInfo "Test getArgs @Rest= default"
function runModArgsTestRest_3() {
  getArgs "a b c @d=9"
  [[ "${a} ${b} ${c} ${d[0]}" == "1 2 3 9" ]] || testFailed
}
runModArgsTest runModArgsTestRest_3

echoInfo "Test getArgs @Rest= default 2"
function runModArgsTestRest_4() {
  getArgs "a b @c=8"
  [[ "${a} ${b} ${c[0]}" == "1 2 3" ]] || testFailed
}
runModArgsTest runModArgsTestRest_4


echoInfo "Test get-Args succeed"
### YOUR CODE ###
