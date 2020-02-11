# DEVOPS libraries for .gitlab-ci.yml #

## Introduction
DevOps Libs is a set of common functionatilities and templates to accelerate DevOps setup processes

### Using Libraries
In order to use this library (i.e: local execution or in GitLab Pipeline) you need to include the DevOps Libs in your project.

In order to use the libraries, you need to follow the steps:

#### 1. Include the library
Download the file `dolibs.sh` placed in the root folder of this repository and copy to: `<YOUR_REPO>/automation/dolibs.sh`

This is the entry point of the library, and once executed (see below) it will automatically retrieve the DevOps Libs code and include for you in your project at `${DOLIBS_DIR}` folder

#### 2. Configure the library

You can edit the `dolibs.sh` inside your project to change some of its characteristics:

|Config|Description|
|-|-|
|`DOLIBS_BRANCH`|Branch from where the lib is cloned (useful to lock a lib version)|
|`DOLIBS_DIR`|Directory where the libraries will be imported on your project|

> `**ATTENTION**`: If you cannot connect to github at port 22, you may need to configure to used port 443, check [this guide](https://help.github.com/en/github/authenticating-to-github/using-ssh-over-the-https-port)

#### 3. Use the libraries
There are two ways to use the libraries:
> `**WARNING**:` GitLab Pipeline uses an environment set with `set -e` which makes the execution to exit at first error (On Local execution it is not the default and your script will continue)

**A. Use the libraries on GitLab Pipelines**
> **Obs:** In this usage, the libraries will not be commited to your repo.

In order to use the libraries, it is only required to include the desired GitLab template (check the available templates) or use the base template and import the librearies you need to use. Let's see an example using the base template:

**.gitlab-ci.yml**
``` yaml
include:
  - project: 'masterleros/bash-devops-libs'
    file: '/pipelines/gitlab/.base-template.yml'

variables:
  DOLIBS_BRANCHES_DEFINITION: "<definitions>"

example_module:
  extends: .base-template
  script:
    - do.import <lib1> <lib2> ... <libN>
    - do.libX.<function> <arg1> <arg2> ... <argN>
```

**B.** Use library for local executions**
> **Obs:** In this usage, the libraries will be addded to your repo (i.e: to redistribute your code).

**automation/cicd/my-script.sh**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh

# Import required lib
do.import gcp

# Consume the lib
do.gcp.useSA ${GOOGLE_APPLICATION_CREDENTIALS}
```

**.gitlab-ci.yml**
``` yaml
example_module:
  script:
    - automation/cicd/my-script.sh
```

> **Tip:** You can use the library in offline mode (use previous downloaded library) by using: `source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh offline`

## Operation Mode
DevOps Liberary have 4 operations modes:

  - **A. Auto (default)** - This mode will attempt to download the liraries if not found locally
  - **B. Online** - This mode will download and update the libraries on all executions
  - **C. Offline** - This Mode will use available libraries, if any is not found, it will fail.
  - **D. local** - Same as `Online` but will copy libraries from a local folder instead of download from GIT (usefull for lib development and testing). To use local mode, you need to set the variable `DOLIBS_LOCAL_MODE_DIR` to the root folder of the library.

You can force the operation mode in the inclusion of the library:
``` yaml
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh offline # or online
```
> **Tip:** To change default operation mode, update `DOLIBS_DEFAULT_MODE` value in `dolibs.sh`

## GitLab Pipeline Requirements
> **Obs:** Templates are definitions of `before_script` and in some cases `after_script`, please be sure you don't need to implement your own mentioned sections as GitLab does not support both (template and custom) section to be merged and only one will be executed.

When using any GitLab template in this library, you will need to define some required values. Each template has it's own requirements, but there are some values that all of them require:

### Git environment variables mapping definition:
The library includes a default functionality to map environment variables depending on the branch name, this is very useful when the pipeline execute activities in different environments, this configuration is made in the global variable `DOLIBS_BRANCHES_DEFINITION`.

**Example:**
``` yaml
variables:
  DOLIBS_BRANCHES_DEFINITION: "feature/*:DEV fix/*:DEV develop:INT release/*:HML bugfix/*:HML master:PRD hotfix/*:PRD"
```

**The above example will map:**

| Branches | Environment |
|-|-|
| `feature/*` and `fix/*` | **DEV** |
| `develop` | **INT** |
| `release/*` and `bugfix/*` | **UAT** |
| `master` and `hotfix/*` | **PRD** |

This will indicate to the templates to convert Environment Variables depending on the building Branch. The format to follow to define those variables is `<ENV>_CI_<VAR>`.

**Definition example:**

| Environment | Var | Value |
|-|-|-|
| **DEV** | DEV_CI_MYVAR | "Hello from DEV!" |
| **INT** | INT_CI_MYVAR | "Hello from INT!" |
| **UAT** | UAT_CI_MYVAR | "Hello from UAT!" |
| **PRD** | PRD_CI_MYVAR | "Hello from PRD!" |

**Execution example:**

Supposing that we are building on `develop` branch an following the above branch definition, we can see:
``` sh
# Current branch = develop

echo ${MYVAR} # This will print: "Hello from INT!"
```

## Global definitions
As a good practice, you can includes the file `automation/definitions.sh`. This is very usefull to define variables/definitions accesibles to your project's scripts globaly. Example:

**automation/definitions.sh**
``` sh
export MY_PROJECT_DESCRIPTION="My cool project!"

function customFunct() {
  getArgs "arg" "${@}"
  echo "My arg is: '${arg}'"
}
```

The above environment variable `MY_PROJECT_DESCRIPTION` and custom function `customFunct()` will be accesibles from you script once you include it:

**automation/cicd/my-script.sh**
``` sh
do.import definitions
do.definitions.customFunct "${MY_PROJECT_DESCRIPTION}"

# Output: My arg is: 'My cool project!'
```

## Additional GitLab Pipeline templates
Check the templates section to check the available templates and their functionalities: [Templates](pipelines/gitlab/README.md)

## Available libraries
Check the available libraries and their functionalities: [Libraries](libs/README.md)
