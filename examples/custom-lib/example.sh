# Enable dolibs (clone to /tmp)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh -l ../..

# Set the custom lib source
do.addCustomSource "mylib" "github.com:masterleros/bash-devops-libs.git"
do.addCustomSource "myotherlib" "github.com:masterleros/bash-devops-libs.git"

# Import the required lib
do.import mylib.some

# Use the needed lib
do.utils.showTitle "Hello DevOps Libs!"