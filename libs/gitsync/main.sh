#!/bin/bash
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
[ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ] && source ${CURRENT_DIR}/../base.sh

# Verify Dependencies
verifyDeps git

# Export internal functions
eval "${useInternalFunctions}"