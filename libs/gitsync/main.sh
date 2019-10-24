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
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "Current Branch: ${current_branch}"

    # Add upstream case is not yet present
    if [ "$(git remote -v | grep ${remote})" ]; then
        git remote remove ${remote}
    fi

    # Add remote
    git remote add ${remote} ${url}

    # Get remote code from upstream
    git fetch ${remote}
    exitOnError

    # Checkout to the desired branch
    git checkout ${branch}
    exitOnError

    # Merge branches
    git merge ${remote}/${branch}

    # Get back to the original branch
    git checkout ${current_branch}
    exitOnError

    # Push remote
    #git push ${remote}

    # Remove upstream remote
    git remote remove ${remote}
}

# Export internal functions
eval "${useInternalFunctions}"