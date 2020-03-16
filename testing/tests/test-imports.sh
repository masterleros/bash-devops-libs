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

source $(dirname "${BASH_SOURCE[0]}")/../../dolibs.sh --online -l ../.. -f /tmp/dolibs

# Set the custom remote lib source
do.addGitSource gitlib "${DOLIBS_REPO}" "${DOLIBS_BRANCH}" libs
exitOnError
do.import gitlib.dummy

# Set the custom lib source
do.addLocalSource locallib $(dirname "${BASH_SOURCE[0]}")/../../libs
exitOnError
do.import locallib.dummy

# Use the custom lib from its own location (not sourcing/copying)
dolibImportLib directlib $(dirname "${BASH_SOURCE[0]}")/../../libs/dummy/main.sh

### VALIDATION CODE ###
gitlib.dummy.doIt "External sourced lib import test!"
locallib.dummy.doIt "Local sourced lib import test!"
directlib.doIt "Direct lib import test!"
### VALIDATION CODE ###
