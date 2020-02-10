## gcp-template
This example clones the libraries, maps branches to environment and rework variables for the detected environemnt (i.e: `<ENV>_CI_MYVAR` -> MYVAR)
Additionally GCP credential.json will be installed from defined environment variables `<ENV>_CI_GCP_CREDENTIAL` to the `GOOGLE_APPLICATION_CREDENTIALS` defined file.

When in the script section, you SA `credential.json` will be already set and ready to go.

``` yaml
include:
  - project: 'masterleros/bash-devops-libs'
    file: '/pipelines/gitlab/.gcp-template.yml'

gcp_module:
  image: google/cloud-sdk:latest  
  extends: .gcp-template
  variables:
    GOOGLE_APPLICATION_CREDENTIALS: "automation/credentials/credential.json"
  script:
    - <gcloud command>
  tag:
    - my-docker-runnner
```