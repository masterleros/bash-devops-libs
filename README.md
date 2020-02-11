# DEVOPS libraries for .gitlab-ci.yml #

## Introduction
DevOps Libs is a set of common functionatilities and templates to accelerate DevOps setup processes

## Folder Structure
``` sh
├── libs              	    (Libraries folder)
│   ├── utils/main.sh       (Additional utils library)
│   ├── gcp/main.sh         (Example: GCP library)
│   ...
│   ├── core.sh             (Core functions library)
│   ├── lib.sh              (lib importer contextualizer)
│   └── main.sh             (DevOps lib functions, i.e: do.import)
└── dolibs.sh               (DevOps Libs entry point)
```

### Using Libraries
In order to use this library (i.e: local execution or in GitLab Pipeline) you need to include the DevOps Libs in your project.

In order to use the libraries, you need to follow the steps:

#### 1. Include the library
Download the file `dolibs.sh` placed in a folder whitin your code, example: `<YOUR_REPO>/dolibs.sh`

This is the entry point of the library, and once executed (see below) it will automatically retrieve the DevOps Libs code and include for you in your project at `${DOLIBS_DIR}` folder

#### 2. Configure the library

You can pass some arguments to your library:

|Argument|Value|Description|
|-|-|-|
|`-b`|`<branch>`|Branch from where the lib is cloned (useful to lock a lib version)|
|`-m`|`<mode>`|Clone mode (check below)|
|`-f`|`<path>`|Default clone root directory|
|`-l`|`<path>`|Use a local folder as the source of libs (i.e: development)|

You can edit the `dolibs.sh` inside your project to change some values globaly:

|Config|Description|
|-|-|
|`DOLIBS_BRANCH`|Default branch from where the lib is cloned (useful to lock a lib version)|
|`DOLIBS_DEFAULT_MODE`|Default clone mode (check below)|

> `**ATTENTION**`: If you cannot connect to github at port 22, you may need to configure to used port 443, check [this guide](https://help.github.com/en/github/authenticating-to-github/using-ssh-over-the-https-port)

#### 3. Use the libraries
> **Obs:** The libraries will be addded to your repo (i.e: to redistribute your code).

**my-script.sh**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh

# Import required lib
do.import gcp

# Consume the lib
do.gcp.useSA ${GOOGLE_APPLICATION_CREDENTIALS}
```

> **Tip:** You can use the library in offline mode (use previous downloaded library) by using: `source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh -m offline`

## Operation Mode
DevOps Liberary have 4 operations modes:

  - **A. Auto (default)** - This mode will attempt to download the liraries if not found locally
  - **B. Online** - This mode will download and update the libraries on all executions
  - **C. Offline** - This Mode will use available libraries, if any is not found, it will fail.
  - **D. local** - Same as `Online` but will copy libraries from a local folder instead of download from GIT (usefull for lib development and testing).

You can force the operation mode in the inclusion of the library:
``` yaml
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh -m offline # or online
```
> **Tip:** To change default operation mode, update `DOLIBS_DEFAULT_MODE` value in `dolibs.sh`

## Global definitions
As a good practice, you can includes the file `definitions.sh`. This is very usefull to define variables/definitions accesibles to your project's scripts globaly. Example:

**definitions.sh**
``` sh
export MY_PROJECT_DESCRIPTION="My cool project!"

function customFunct() {
  getArgs "arg" "${@}"
  echo "My arg is: '${arg}'"
}
```

The above environment variable `MY_PROJECT_DESCRIPTION` and custom function `customFunct()` will be accesibles from you script once you include it:

**my-script.sh**
``` sh
do.import definitions
do.definitions.customFunct "${MY_PROJECT_DESCRIPTION}"

# Output: My arg is: 'My cool project!'
```

## External Libraries

To include external libraries, you can use the function `do.addCustomSource` to add an external GIT source, then name it as a new namespace:

**example.sh**
``` sh
# Enable dolibs (clone to /tmp)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh -f /tmp

# Set the custom lib namespace and source (optionally the branch)
do.addCustomSource "mycustomlib" "github.com:masterleros/bash-devops-libs.git" "branch"

# Import the required lib
do.import mycustomlib.utils

# Use the needed lib
do.mycustomlib.utils.showTitle "Hello DevOps Libs!"
```

## Available libraries
Check the available libraries and their functionalities: [Libraries](libs/README.md)
