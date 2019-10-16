# GFT libraries for .gitlab-ci.yml #

Usage: (in your .gitlab-ci.yml)

``` yaml
include:
  - project: 'devops-br/banking-gft-scripts'
    file: '/.gitlab-ci.devops-lib.yml' 

test_module:
  extends: .gft-libs
  script:
    - import_gft_libs DEVOPS GCP ETC
```