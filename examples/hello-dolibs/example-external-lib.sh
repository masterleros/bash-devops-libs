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

# Enable dolibs
source $(dirname "${BASH_SOURCE[0]}")/../../dolibs.sh -f /tmp/dolibs -l ../.. --online

# Add the external lib source from GIT into the 'myremotelib' namespace
# and import one of its modules
do.addGitSource gitlib "${DOLIBS_REPO}" "${DOLIBS_BRANCH}" libs
exitOnError
do.import gitlib.dummy

# Add the external local lib source into the  'locallib' namespcae
# and import one of its modules
do.addLocalSource locallib $(dirname "${BASH_SOURCE[0]}")/../../libs
exitOnError
do.import locallib.dummy

# Use external gitlib
echoInfo "Testing from 'gitlib'"
gitlib.dummy.doIt "any value"

# Use external locallib
echoInfo "Testing from 'locallib'"
locallib.dummy.doIt "any value"

echoInfo "See you!"