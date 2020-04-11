#!/bin/bash
#    Copyright 2020 Leonardo Andres Morales

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# Enable dolibs (offline)
source $(dirname "${BASH_SOURCE[0]}")/../../dolibs.sh --offline

do.use dialogs

function show_dialog_example() {
  dialogs.showConfigurationDialog "Please configure id and age" "
    string my_id
    number my_age
    password my_password
  "
}

function show_askValue_example() {
  dialogs.askValue string my_name "Please set Id"
}

function run_examples() {
  local my_id=${USER}
  local my_age=27
  local my_password=
  local my_name=baroni
  show_dialog_example
  show_askValue_example
  clear
  echoInfo "my_id: ${my_id}"
  echoInfo "my_age: ${my_age}"
  echoInfo "my_password: ${my_password}"
  echoInfo "my_name: ${my_name}"
}
run_examples
