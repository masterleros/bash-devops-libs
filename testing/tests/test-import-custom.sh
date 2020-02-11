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

#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh -f /tmp

# Set the custom remote lib source
do.addCustomGitSource customlib "github.com/masterleros/bash-devops-libs.git" master
exitOnError
do.import customlib.utils

# Set the custom lib source
do.addLocalSource $(dirname ${BASH_SOURCE[0]})/../../libs
exitOnError
do.import local.utils

### YOUR CODE ###
do.customlib.utils.showTitle "External lib import test!"
do.local.utils.showTitle "Local lib import test!"
### YOUR CODE ###