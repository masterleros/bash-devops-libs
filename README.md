# GITLAB libraries for .gitlab-ci.yml #

## Introduction
GitLab Libs is a set of common functionatilities and templates to speed up DevOps setup processes

> **Obs:** Templates are definitions of `before_script` and in some cases `after_script`, please be sure you don't need to implement your own mentioned sections as GitLab does not support both (template and custom) section to be merged and only one will be executed.

## Folder Structure
``` sh
├── libs              	    (Libraries folder)
│   ├── utils               (Additional utils library)
│   ├── gcp                 (Example: GCP library)
│   ...
│   └── common.sh           (Common/base functions library)
├── templates               (Templates folders)
│   └── .gcp-template.yml   (Example: GCP templates)
└── .gitlab-libs.yml        (Main GitLab Libs include)
```

### Requirements
Before you use this GitLab library you need to include and define repository and branch mappings

``` yaml
include:
  - project: 'devops-br/gitlab-gft-libs'
    file: '/.gft-libs.yml' 

variables:
  ################# GITLAB LIBS DEFINITIONS #################
  GITLAB_LIBS_REPO: "devops-br/gitlab-gft-libs"
  GITLAB_LIBS_BRANCHES_DEFINITION: "feature/*:DEV fix/*:DEV develop:INT release/*:HML bugfix/*:HML master:PRD hotfix/*:PRD"
  ################# GITLAB LIBS DEFINITIONS #################
```

## Use template that includes librearies from GITLAB Libs
This example clones the libraries and import the desired ones in the script section

``` yaml
test_module:
  extends: .gitlab-libs-template
  script:
    - import_gitlab_libs DEVOPS GCP ETC
```

## Use the common template
This example clones the libraries, maps branches to environment and rework variables for the detected environemnt (i.e: `<ENV>_CI_MYVAR` -> MYVAR)

``` yaml
test_module:
  extends: .gitlab-common-template
```

## Use the common template
This example clones the libraries, maps branches to environment and rework variables for the detected environemnt (i.e: `<ENV>_CI_MYVAR` -> MYVAR)
Additionally GCP credential.json will be installed from defined environment variables `<ENV>_CI_GCLOUD_CREDENTIAL` to the `<ENV>_CI_GOOGLE_APPLICATION_CREDENTIALS` defined file.

When in the script section, you SA `credential.json` will be already set and ready to go.

``` yaml
include:
  ...
  - project: 'devops-br/gitlab-gft-libs'
    file: '/templates/.gcp-template.yml'

gcp_module:
  image: google/cloud-sdk:latest  
  extends: .gcp-template
  script:
    - <gcloud command>
  tag:
    - my-docker-runnner
```