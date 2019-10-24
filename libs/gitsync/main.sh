#!/bin/bash
eval "${importBaseLib}"

# Verify Dependencies
verifyDeps git

### Synchronize a GIT repository with current code
# usage: sync <git_url>
function sync() {

    getArgs "url branch" "${@}"

    # Remote repository to sync and current branch
    remote="gitsync"
    
    # Get the origin code from the required branch
    git fetch origin ${branch}

    git branch

    # Add upstream case is not yet present
    if [ "$(git remote -v | grep ${remote})" ]; then
        git remote remove ${remote}
    fi

    # Add remote
    git remote add ${remote} ${url}
    exitOnError

    # Push remote
    echo "Sending code to the remote repository '${url}' at branch '${branch}'"
    git push ${remote} ${branch}
    exitOnError

    # Remove upstream remote
    git remote remove ${remote}
}

# Export internal functions
eval "${useInternalFunctions}"