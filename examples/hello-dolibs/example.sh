# Enable dolibs (clone to /tmp)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh -f /tmp

# Import the required lib
do.import utils

# Use the needed lib
do.utils.showTitle "Hello DevOps Libs!"