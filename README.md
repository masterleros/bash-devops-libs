# DEVOPS libraries for .gitlab-ci.yml #

## Introduction
DevOps Libs is a set of common functionatilities and templates to accelerate DevOps setup processes

## Folder Structure
``` sh
├── libs              	    (Libraries folder)
│   ├── utils               (Additional utils library)
│   ├── gcp                 (Example: GCP library)
│   ...
│   └── base.sh             (Base functions library)
├── gitlab                  (GitLab templates folders)
│   ├── .base-template.yml  (Basic GitLab DevOps Libs template)
│   └── .gcp-template.yml   (Example: GitLab DevOps GCP Libs templates)
└── devops-libs.sh          (DevOps Libs management)
```

### Using Libraries
In order to use this library (i.e: local execution or in GitLab Pipeline) you need to include the DevOps Libs in your project.

In order to use the libraries, you need to follow the steps:

#### 1. Include the library
Download the file `devops-libs.sh` placed in the root folder of this repository and copy to: `<YOUR_REPO>/scripts/devops-libs.sh`

This is the entry point of the library, and once executed (see below) it will automatically retrieve the DevOps Libs code and include for you in your project at `${DEVOPS_LIBS_PATH}` folder

#### 2. Configure the library

You can edit the `devops-libs.sh` inside your project to change some of its characteristics:

|Config|Description|
|-|-|
|`DEVOPS_LIBS_BRANCH`|Branch from where the lib is cloned (useful to lock a lib version)|
|`DEVOPS_LIBS_PATH`|Directory where the libraries will be imported on your project|

#### 3. Use the libraries
There are two ways to use the libraries:
> `**WARNING**:` GitLab Pipeline uses an environment set with `set -e` which makes the execution to exit at first error (On Local execution it is not the default and your script will continue)

**A. Use the libraries on GitLab Pipelines**
> **Obs:** In this usage, the libraries will not be commited to your repo.

In order to use the libraries, it is only required to include the desired GitLab template (check the available templates) or use the base template and import the librearies you need to use. Let's see an example using the base template:

**.gitlab-ci.yml**
``` yaml
include:
  - project: 'devops-br/gitlab-gft-libs'
    file: '/gitlab/.base-template.yml'

variables:
  DEVOPS_LIBS_BRANCHES_DEFINITION: "<definitions>"

example_module:
  extends: .base-template
  script:
    - importLibs <lib1> <lib2> ... <libN>
    - libXlib.<function> <arg1> <arg2> ... <argN>
```

**B.** Use library for local executions**
> **Obs:** In this usage, the libraries will be addded to your repo (i.e: to redistribute your code).

**scripts/cicd/my-script.sh**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh

# Import required lib
importLibs gcp

# Consume the lib
gcplib.useSA ${GOOGLE_APPLICATION_CREDENTIALS}
```

**.gitlab-ci.yml**
``` yaml
example_module:
  script:
    - scripts/cicd/my-script.sh
```

> **Tip:** You can use the library in offline mode (use previous downloaded library) by using: `source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh offline`

## Operation Mode
DevOps Liberary have 3 operations modes:

  - **A. Auto (default)** - This mode will attempt to download the liraries if not found locally
  - **B. Online** - This mode will download and update the libraries on all executions
  - **C. Offline** - This Mode will use available libraries, if any is not found, it will fail.

You can force the operation mode in the inclusion of the library:
``` yaml
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh offline # or online
```

## GitLab Pipeline Requirements
> **Obs:** Templates are definitions of `before_script` and in some cases `after_script`, please be sure you don't need to implement your own mentioned sections as GitLab does not support both (template and custom) section to be merged and only one will be executed.

When using any GitLab template in this library, you will need to define some required values. Each template has it's own requirements, but there are some values that all of them require:

### Git environment variables mapping definition:
The library includes a default functionality to map environment variables depending on the branch name, this is very useful when the pipeline execute activities in different environments, this configuration is made in the global variable `DEVOPS_LIBS_BRANCHES_DEFINITION`.

**Example:**
``` yaml
variables:
  DEVOPS_LIBS_BRANCHES_DEFINITION: "feature/*:DEV fix/*:DEV develop:INT release/*:HML bugfix/*:HML master:PRD hotfix/*:PRD"
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
This library includes an automated inclusion of the file `scripts/definitions.sh`. This is very usefull to define variables/definitions accesibles to your project's scripts globaly. Example:

**scripts/definitions.sh**
``` sh
export MY_PROJECT_DESCRIPTION="My cool project!"
```

The above environment variable `MY_PROJECT_DESCRIPTION` will be accesible locally and in the DevOps Automation.

## Additional GitLab Pipeline templates
Check the templates section to check the available templates and their functionalities: [Templates](gitlab/README.md)

## Available libraries
Check the available libraries and their functionalities: [Libraries](libs/README.md)
