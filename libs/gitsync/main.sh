#!/bin/bash
eval "${importBaseLib}"

# Verify Dependencies
verifyDeps git

# Export internal functions
eval "${useInternalFunctions}"