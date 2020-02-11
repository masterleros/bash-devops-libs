# Enable dolibs (clone to /tmp)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh -f .

# Set the custom lib source
do.addCustomSource "mycustomlib" "github.com:masterleros/bash-devops-libs.git"

# Import the required lib
do.import mycustomlib.utils

# Use the needed lib
do.mycustomlib.utils.showTitle "Hello DevOps Libs!"