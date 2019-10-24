# GITLAB libraries for .gitlab-ci.yml #

## Introduction
GitLab Libs is a set of common functionatilities and templates to accelerate DevOps setup processes

> **Obs:** Templates are definitions of `before_script` and in some cases `after_script`, please be sure you don't need to implement your own mentioned sections as GitLab does not support both (template and custom) section to be merged and only one will be executed.

## Folder Structure
``` sh
├── libs              	    (Libraries folder)
│   ├── utils               (Additional utils library)
│   ├── gcp                 (Example: GCP library)
│   ...
│   └── base.sh             (Base functions library)
├── templates               (Templates folders)
│   ├── .base-template.yml  (Basic GitLab Libs template)
│   └── .gcp-template.yml   (Example: GCP templates)
└── gitlab-libs.sh          (GitLab Libs management)
```

### Using Libraries
In order to use this library (i.e: local execution or in GitLab Pipeline) you need to include the GitLab Libs in your project.

In order to use the libraries, you need to follow the steps:

#### 1. Include the library
Download the file `gitlab-libs.sh` placed in the root folder of this repository and copy to: `<YOUR_REPO>/scripts/gitlab-libs.sh`

This is the entry point of the library, and once executed (see below) it will automatically retrieve the GitLab Libs code and include for you in your project at `${GITLAB_LIBS_DIR}` folder

#### 2. Configure the library

You can edit the `gitlab-libs.sh` inside your project to change some of its characteristics:

|Config|Description|
|-|-|
|`GITLAB_LIBS_BRANCH`|Branch from where the lib is cloned (useful to lock a lib version)|
|`GITLAB_LIBS_DIR`|Directory where the libraries will be imported on your project|

> **Warning:** Do not change `GITLAB_LIBS_ONLINE_MODE` definition, to use the library in offline mode, check the local examples below.

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
    file: '/templates/.base-template.yml'

variables:
  GITLAB_LIBS_BRANCHES_DEFINITION: "<definitions>"

example_module:
  extends: .base-template
  script:
    - import_gitlab_libs <lib1> <lib2> ... <libN>
    - libXlib.<function> <arg1> <arg2> ... <argN>
```

**B.** Use library for local executions**
> **Obs:** In this usage, the libraries will be addded to your repo (i.e: to redistribute your code).

**scripts/cicd/my-script.sh**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/../gitlab-libs.sh

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

> **Tip:** You can use the library in offline mode (use previous downloaded library) by using: `source $(dirname ${BASH_SOURCE[0]})/../gitlab-libs.sh offline`

## GitLab Pipeline Requirements
When using any GitLab template in this library, you will need to define some required values. Each template has it's own requirements, but there are some values that all of them require:

### Git environment variables mapping definition:
The library includes a default functionality to map environment variables depending on the branch name, this is very useful when the pipeline execute activities in different environments, this configuration is made in the global variable `GITLAB_LIBS_BRANCHES_DEFINITION`.

**Example:**
``` yaml
variables:
  GITLAB_LIBS_BRANCHES_DEFINITION: "feature/*:DEV fix/*:DEV develop:INT release/*:HML bugfix/*:HML master:PRD hotfix/*:PRD"
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

The above environment variable `MY_PROJECT_DESCRIPTION` will be accesible locally and in the GitLab Automation.

## Additional Templates
Check the templates section to check the available templates and their functionalities: [Templates](templates/README.md)

## Available librearies
Check the available libraries and their functionalities: [Libraries](libs/README.md)
