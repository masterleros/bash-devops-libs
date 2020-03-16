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


# Verify Dependencies
checkBins git || return ${?}

### Synchronize a GIT repository with current code
# usage: sync <git_url>
function sync() {

    getArgs "url branch"

    # Verify Dependencies
    checkBins git || return ${?}

    # Remote repository to sync and current branch
    remote="gitsync"
    
    # Add upstream case is not yet present
    if [ "$(git remote -v | grep ${remote})" ]; then
        git remote remove "${remote}"
    fi

    # Add remote
    git remote add "${remote}" "${url}"
    exitOnError

    # Push remote
    echoInfo "Sending code to the remote repository '${url}' at branch '${branch}'"
    if [ "${branch}" != "${CI_COMMIT_REF_NAME}" ]; then
        # Get the origin code from the required branch
        git fetch origin "${branch}"

        # Push to remote
        git push "${remote}" "${branch}"
    else
        # Push head to remote
        git push "${remote}" HEAD:refs/heads/"${branch}"
    fi
    exitOnError

    # Remove upstream remote
    git remote remove "${remote}"
}
