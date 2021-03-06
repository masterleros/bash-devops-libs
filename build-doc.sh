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

source $(dirname "${BASH_SOURCE[0]}")/dolibs.sh --offline

# Generate documentaton for the core lib
do.document "${DOLIBS_CORE_DIR}" "${DOLIBS_DOCUMENTATION_DIR}"/core.md

# For each included lib
INCLUDED_DOLIBS=($(find "${DOLIBS_LIBS_DIR}" -maxdepth 1 -mindepth 1 -type d))
for INCLUDED_DOLIB in ${INCLUDED_DOLIBS[@]}; do
    CURRENT=$(basename "${INCLUDED_DOLIB}")

    # Generate documentaton for the current lib
    do.document "${INCLUDED_DOLIB}" "${DOLIBS_DOCUMENTATION_DIR}/${CURRENT}".md "${CURRENT}"
done