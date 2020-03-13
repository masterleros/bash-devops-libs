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

# Import the custom lib from its location
# Check the ./customlib folder to look at this code
dolibImportLib customlib $(dirname "${BASH_SOURCE[0]}")/customlib/main.sh

# Use my custom function
customlib.doSome "a value"