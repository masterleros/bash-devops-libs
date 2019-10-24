#!/bin/bash
CURRENT_DIR=$(dirname ${BASH_SOURCE[0]})
[ $(basename $0) == $(basename ${BASH_SOURCE[0]}) ] && source ${CURRENT_DIR}/../libs/base.sh

# Verify Dependencies
verifyDeps terraform

# Export internal functions
eval "${useInternalFunctions}"