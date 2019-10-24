#!/bin/bash
eval "${importBaseLib}"

# Verify Dependencies
verifyDeps git

### Synchronize a GIT repository with current code
# usage: sync <git_url>
function sync() {

    getArgs "url &branch" "${@}"

    # Remote repository to sync and current branch
    remote="gitsync"    

    # If not branch specified, use current one
    if [ ! $branch ]; then
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        echo "Branch not specified, used current: '${current_branch}'"
        branch=${current_branch}
    fi

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