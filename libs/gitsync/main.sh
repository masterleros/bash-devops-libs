#!/bin/bash

# Verify Dependencies
verifyDeps git

### Synchronize a GIT repository with current code
# usage: sync <git_url>
function sync() {

    getArgs "url branch" "${@}"

    # Remote repository to sync and current branch
    remote="gitsync"
    
    # Add upstream case is not yet present
    if [ "$(git remote -v | grep ${remote})" ]; then
        git remote remove ${remote}
    fi

    # Add remote
    git remote add ${remote} ${url}
    exitOnError

    # Push remote
    echoInfo "Sending code to the remote repository '${url}' at branch '${branch}'"
    if [[ "${branch}" != "${CI_COMMIT_REF_NAME}" ]]; then
        # Get the origin code from the required branch
        git fetch origin ${branch}

        # Push to remote
        git push ${remote} ${branch}
    else
        # Push head to remote
        git push ${remote} HEAD:refs/heads/${branch}
    fi
    exitOnError

    # Remove upstream remote
    git remote remove ${remote}
}
