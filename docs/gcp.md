* [gcp.api.enable()](#gcpapienable)
* [gcp.auth.getCurrentUser()](#gcpauthgetcurrentuser)
* [gcp.auth.getValueFromCredential()](#gcpauthgetvaluefromcredential)
* [gcp.auth.createSA()](#gcpauthcreatesa)
* [gcp.auth.useSA()](#gcpauthusesa)
* [gcp.auth.revokeSA()](#gcpauthrevokesa)
* [gcp.auth.createCredential()](#gcpauthcreatecredential)
* [gcp.auth.deleteCredential()](#gcpauthdeletecredential)
* [gcp.firestore.enabledProject()](#gcpfirestoreenabledproject)
* [gcp.gae.deploy()](#gcpgaedeploy)
* [gcp.gcf.deploy()](#gcpgcfdeploy)
* [gcp.gcr.dockerLogin()](#gcpgcrdockerlogin)
* [gcp.gcr.dockerLogoff()](#gcpgcrdockerlogoff)
* [gcp.gcr.getImageDigest()](#gcpgcrgetimagedigest)
* [gcp.gcr.getFullDigestTag()](#gcpgcrgetfulldigesttag)
* [gcp.gcr.buildAndPublish()](#gcpgcrbuildandpublish)
* [gcp.gcs.validateBucket()](#gcpgcsvalidatebucket)
* [gcp.gcs.createBucket()](#gcpgcscreatebucket)
* [gcp.gcs.enableVersioning()](#gcpgcsenableversioning)
* [gcp.gcs.setUserACL()](#gcpgcssetuseracl)
* [gcp.gke.loginCluster()](#gcpgkelogincluster)
* [gcp.gke.describeCluster()](#gcpgkedescribecluster)
* [gcp.iam.validateRole()](#gcpiamvalidaterole)
* [gcp.iam.bindRole()](#gcpiambindrole)
* [gcp.useProject()](#gcpuseproject)
* [gcp.setDefaultZone()](#gcpsetdefaultzone)



# gcp.api.enable()

Enable a API domain into the GCP project

### Arguments

* **project** (id): of the GCP project
* **api** (id): of the API to enable

### Exit codes

* **0**: API successfuly enabled
* non-**0**: Failed to enable API

### Example

```bash
enable <project> <api>
```




# gcp.auth.getCurrentUser()

Get a value from the credential json file

### Return value

* User e-mail

### Example

```bash
assign currentUserEmail=getCurrentUser()
```

# gcp.auth.getValueFromCredential()

Get a value from the credential json file

### Arguments

* $credential_file path to a GCP credential file
* **key** (key): inside the credential file json

### Return value

* Desired key value

### Example

```bash
assign key_value=getValueFromCredential <credential_file> <key>
```

# gcp.auth.createSA()

Create a service account with the given parameters

### Arguments

* **project** (id): of the project
* $sa_id id of the service account
* $[description] optional description

### Exit codes

* **0**: Successfuly created SA
* non-**0**: Failed to create SA

### Example

```bash
createSA <project> <sa_id> [description]
```

# gcp.auth.useSA()

Validates and use the service account from file

### Arguments

* $credential_file path to a GCP credential file

### Exit codes

* **0**: Successfuly set SA
* non-**0**: Failed to set SA

### Example

```bash
useSA <credential_file>
```

# gcp.auth.revokeSA()

Remove the service account from system

### Arguments

* $credential_file path to a GCP credential file

### Exit codes

* **0**: Successfuly revoked SA
* non-**0**: Failed to revoked SA

### Example

```bash
revokeSA <credential_file>
```

# gcp.auth.createCredential()

Create a service account credential json file

### Arguments

* **project** (id): of the project
* $credential_path path to create a GCP credential file
* $sa_mail email of the SA

### Exit codes

* **0**: Successfuly created SA
* non-**0**: Failed to created SA

### Example

```bash
createCredential <project> <credential_path> <sa_mail>
```

# gcp.auth.deleteCredential()

Delete a SA credential of the project

### Arguments

* **project** (id): of the project
* $credential_path path to delete a GCP credential file
* $sa_mail email of the SA

### Exit codes

* **0**: Successfuly delete SA
* non-**0**: Failed to delete SA

### Example

```bash
deleteCredential <project> <credential_path> <sa_mail>
```




# gcp.firestore.enabledProject()

Validate if the project is firestore enabled

### Arguments

* **project** (id): of the project

### Return value

* 0 Project set
* non-0 Failed to set project

### Example

```bash
enabledProject <project_id>
```




# gcp.gae.deploy()

Deploys an Google AppEngine application

### Arguments

* **path** (to): the description of the AppEngine application
* $[path] optional version idenfitier

### Exit codes

* **0**: GAE app deployed
* non-**0**: GAE app not deployed

### Example

```bash
 deploy <path> [version]
```




# gcp.gcf.deploy()

Deploy a Cloud Function

### Arguments

* **cfName** (name): of the cloud functions
* @$parameters the cloud function parameters

### Exit codes

* **0**: Cloud Function deployed successfuly
* non-**0**: Cloud Function failed to deploy

### Example

```bash
deploy <function name> <aditional_parameters_array_list>
```




# gcp.gcr.dockerLogin()

Login with current GOOGLE_APPLICATION_CREDENTIALS to GCloud registry

### Exit codes

* **0**: Logged in successfuly
* non-**0**: Logged in failed

### Example

```bash
dockerLogin()
```

# gcp.gcr.dockerLogoff()

Logoff of current GCloud registry

### Example

```bash
dockerLogoff()
```

# gcp.gcr.getImageDigest()

Get the digest of a specific tagged image

### Arguments

* $project_id id of the GCP project
* $docker_image_name name of the docker image
* $docker_image_tag tag of the docker image

### Return value

* digest of an image

### Example

```bash
getImageDigest <project_id> <docker_image_name> <docker_image_tag>
```

# gcp.gcr.getFullDigestTag()

Get the full digest path (with registry/project/image/digest) of a specific tagged image

### Arguments

* $project_id id of the GCP project
* $docker_image_name name of the docker image
* $docker_image_tag tag of the docker image

### Return value

* digest of an image

### Example

```bash
getFullDigestTag <project_id> <docker_image_name> <docker_image_tag>
```

# gcp.gcr.buildAndPublish()

Build a docker image and publish to the GCP Container Registry

### Arguments

* $project_id id of the GCP project
* $docker_dir path to a directory containing an docker file
* $docker_file filename of the docker to be build
* $docker_image_name name of the resulting docker image
* @$docker_builder_args optional rest arguments for docker builder args

### Return value

* digest of an image

### Example

```bash
buildAndPublish <project_id> <docker_dir> <docker_file> <docker_image_name> <docker_build_args>
```




# gcp.gcs.validateBucket()

Check if a bucket exist

### Arguments

* **project** (id): of the GCP project
* **bucket** (name): of the bucket to check

### Return value

* 0 if bucket exist

### Example

```bash
validateBucket <project> <bucket>
```

# gcp.gcs.createBucket()

Create a bucket if it does not exist

### Arguments

* **project** (id): of the GCP project
* **bucket** (name): of the bucket to create
* **class** ('regional'): or 'multiregional'
* $[region] optional region

### Exit codes

* **0**: Bucket created
* non-**0**: Bucket not created due to error

### Example

```bash
createBucket <project> <bucket> <class> [region]
```

# gcp.gcs.enableVersioning()

Enable versioning into a bucket

### Arguments

* **bucket** (name): of the bucket to enable versioning

### Exit codes

* **0**: Bucket versioning enabled
* non-**0**: Bucket versioning not enabled

### Example

```bash
enableVersioning <bucket>
```

# gcp.gcs.setUserACL()

Enable versioning into a bucket

### Arguments

* **bucket** (name): of the bucket to enable versioning
* $user
* **ACL** (one): of:

### Exit codes

* **0**: Bucket ACL set
* non-**0**: Bucket ACL not set

### Example

```bash
setACL <bucket> <user> <ACL>
```




# gcp.gke.loginCluster()

Set the requested project and then get credentials for the cluster

### Arguments

* $cluster_name name of the cluster to login
* **zone** (zone): of the cluster
* **project** (id): of the GCP project

### Exit codes

* **0**: Successfuly logged in
* non-**0**: Unable to login

### Example

```bash
loginCluster <cluster_name> <zone> <project_id>
```

# gcp.gke.describeCluster()

Describe a cluster

### Arguments

* $cluster_name name of the cluster to describe
* **zone** (zone): of the cluster
* **project** (id): of the GCP project

### Return value

* the description of the cluster

### Example

```bash
assign description=describeCluster <cluster_name> <zone> <project_id>
```




# gcp.iam.validateRole()

Validates if a email contains certain role

### Arguments

* **domain** (one): of: project folder billing function
* $domain_id id into the domain
* **role** (name): of the role to verify
* **email** (email): to verify the role

### Return value

* exit code

### Exit codes

* **0**: Role is defined for email
* non-**0**: Role is not defined for email

### Example

```bash
validateRole <domain> <domain_id> <role> <email>
```

# gcp.iam.bindRole()

Bind Role to a list of emails

### Arguments

* **domain** (one): of: project folder function
* $domain_id id into the domain
* **role** (name): of the role to verify
* @$emails list of emails

### Exit codes

* **0**: Successfuly bind roles
* non-**0**: Failed to bind roles

### Example

```bash
bindRole <domain> <domain_id> <role> <email1> <email2> ... <emailN>
```




# gcp.useProject()

Validate and set the requested project

### Arguments

* $project_id id of the project

### Exit codes

* **0**: Project set
* **1**: Project not found

### Example

```bash
useProject <project_id>
```

# gcp.setDefaultZone()

Set default configuration for project zone

### Arguments

* **zone** (desired): GCP zone

### Example

```bash
setDefaultZone us-west1-a
```

