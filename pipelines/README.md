> `**WIP**`

# GitLab Project Set up

### 1. Protected branches

Protecting branch means to disallow developers to commit direct to them, avoiding unexpected deployments.  
It forces developers to integrate code by using `merge requests`.

1. First go to your GitLab Project then create the develop branch:  
Branches `>` New `>` Branch name: **develop**  
2. Now set it as default branch:  
Settings `>` Repository `>` Default Branch: **develop**

3. Finally go **Settings `>` Repository `>` Protected Branches** and protect both develop and master branches as below:

|Branch|Allowed to merge|Allowed to push|
|-|-|-|
|`master`|`Maintainers`|`No one`|
|`develop`|`Maintainers`|`No one`|

The code to these branches will be only updated throught merge requests.  
This ensures to not break the protected branches and force, by using the merge requests, approvals to code review on them.

### 2. Merge Request conditions

A pipeline will be triggered as soon as a merge request is created. In case of pipeline failure on that stage, `reviewers` will not be able to accept the merge. This implies on developers to rework the code to fix the issue.

* To set this pre condition go to **Settings `>` General `>` Merge Requests** and tick option as below:
- [x] **Only allow merge requests to be merged if the pipeline succeeds**

# GitLab CI/CD Pipeline Set up

### Overview

Gitlab Pipelines are used to perform Continuous Integration and Continuous Delivery.

|**Configuration File**|**Description**|
|-|-|
**`repository`/.gitlab-ci.yaml**|Contains develop branch reference that will run pipeline and call cicd configuration file as per 'include' section|

### Runners setup 
A Runner in gitlab is an agent that executes the pipeline requisitions. It can run several executors such as **docker** or **shell**  
Follow Gitlab documentation to install a runner in a server: https://docs.gitlab.com/runner/

In the configuration file set the tags using the runner name as the example below:

``` yml
tags:
  - runner-name-type
```

# GitLab Workflow

### Overview
Best practices on branch names help the pipeline to deploy into the correct Environment.

To use Gitlab CI/CD pipeline your branch has to follow these patterns.

### Branch Management

The actual development will happen from intermediate branches except from develop and master.  
Developers will be able to create branches from develop or master according to the conditions below:

|Source branch|Development branch name|Description|Merge request to|
|-|-|-|-|
|`master`|`hotfix/*`|When there is a bug on production and needs to be corrected immidetially|`master`<br>`develop`|
|`develop`|`feature/*`<br>`fix/*`|When developing new features and/or fixes on non production code|`develop`|
|`develop`|`release/*`|When there is a release candidate (i.e: code freeze)|`master`<br>`develop` (Only when bugfix)|
|`release/*`|`bugfix/*`|When fixing a release candidate|`release/*`|

> `**Note**`: After code is merged into master, a `tag` must be created to snapshot the release version

## Configure the pipeline for the Branching Model

Each branch is mapped to specifics Environments within your solution.  
This can be more detailed here: [GitLab Libs Mapping definition](../README.md#git-environment-variables-mapping-definition)

Having that on mind, you will need to set up your pipeline to work according to it.  
To accomplish that, you will need to have `conditions` to:  
* **when** to trigger the pipeline
* **where** to deploy the code

## Step trigger conditions

Every **commit** will trigger the pipeline and deploy according to the `branch-to-environment` mapping.  
For that you need to include the following condition to the pipeline configuration file:

|Environment|Condition String|
|-|-|
|**DEV**| /^((feature/.*)|(fix/.*))$/```|
|**INT**| /^(develop)$/ |
|**UAT**| /^((release/.*)|(bugfix/.*))$/ |
|**PRD**| /^((master)|(hotfix/.*))$/ |

* Condition example:
```yaml
sample-step:
  (...)
  only:
    refs: 
      - <ENV Condition String>
```

### For multi-application projects

In a multi-application project, one more aspect must be considered. The pipeline must accomplish with addicional conditions which informs which application has been changed.  
* For example, your project has multiple application separated in folders as in the structure below:
``` sh
├── app-x
├── app-y
├── frontend
└── backend
```

Let say that you develop a code change in `app-x` and you want to trigger the pipeline. The pipeline should run only the steps regarding to `app-x`.  
For that, the pipeline configuration file must contain the application folder reference (the tag `changes`):
* Target environment: `DEV`
```yaml
only:
    refs: 
      - /^((feature/.*)|(fix/.*))$/
    changes: 
      - app-x/**/*
```

## Branch validation step

Any named branch that is not alligned with Branch Model must be ignored, so that the pipeline avoids to run non-compliant branches.  
For Example, branch named `stress-test/develop` will not be considered as valid and will fail the pipeline.

```yaml
stages:
  - Validation

( ... )

Bad Branch Name:
  stage: Validation
  script:
    - echo "Branch name '${CI_COMMIT_REF_NAME}' is not supported, please contact support and rename you branch!"
    - exit -1
  except:
    refs:
      - /^((master)|(hotfix/.*)|(develop)|(feature/.*)|(fix/.*)|(release/.*)|(bugfix/.*))$/
```
