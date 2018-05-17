# [WIP] Log Aggregation Terraform

## Installation and Dependencies
---

Using this configuration for the first time requires some setup:
1. Terraform version 0.11.3 is required.
1. Terraform AWS provider version 1.8 is required.
  1. Run `terraform init` to update the provider.
1. An S3 bucket for remote state storage
  1. Using the bucket for remote state storage requires the bucket's information to be explicitly typed in a terraform block, e.g.
    ```
    terraform {
      backend "s3" {
        bucket = "remote-state-bucket"
        key = "states/project/terraform.tfstate"
        region = "us-west-2"
      }
    }
    ```
1. A shared AWS credentials file somewhere. The python management wrapper defaults to `~/.aws/credentials`. Must use the form:
    ```
    [profile-name]
    aws_region = us-east-1
    aws_access_key_id = AAAAAA
    aws_secret_access_key = BBBBBB
    ```
  1. Note that the profile must explicitly list the access and secret keys; role assumption is technically possible but does not lend itself to version control well.

*You may wish to run *`terraform plan|apply`* first and create the S3 backend
_first_, temporarily relying on locally-stored state. If so, hide the
remote\_config.tf file: `mv remote_config.tf .remote_config.tf` first.* See
Usage below.

When your bucket is ready, you may initialize the project. This will require exporting AWS credentials to environment variables:
```
profile="profile-name" # see AWS credentials file example above
export AWS_REGION=$(aws configure get ${profile}.region)
export AWS_ACCESS_KEY_ID=$(aws configure get ${profile}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${profile}.aws_secret_access_key)
terraform init
```

If you used local state first, you will be asked if you wish to transfer state; type `yes`.


## Setup
---

In order to make working with Terraform easier, especially with respect to
testing/running it in multiple AWS accounts, there is a python wrapper which
enforces Terraform configuration based on IAM access. This will likely be a
lengthy work in progress. Whenever you begin work on the project, you should
set up your environment:

1. `source setup.sh`
  1. This will provide the python terraform management wrapper (run\_tf.py) with the necessary environment.


## Use
---
`python run_tf.py <profile_name> [-a <action>]`


### Use With Modules
---

If you have introduced a new (sub)module, you will need to `get` the module first:

```
python run_tf.py <profile_name> -a get
```


## Some Notes On Lambdas
---

### Python and External Modules
---

Some submodules may contain configurations for setting up AWS Lambdas and the
source code for those Lambdas. When the Lambda is written in Python and
requires external python modules, those modules can be installed by pip into
the Lambda's root directory:

```
pip install ${external_module} -t ${path_to_lambda_source}
```

Check the submodule's directory for a README.md file indicating this necessity
as it is preferred _not_ to track the external module's code in git and is thus
ignored with a .gitignore in the submodule.


### Copying Lambdas Across Terraform Modules
---

Ideally, a lambda's source could would be stored in one directory in this git
project and referred to by submodules. Unfortunately, if the source is at the
same level as or above the submodule's directory (e.g. the lambda source is not
a child of the submodule) then Terraform will complain and fail.

As a result, any Lambdas used by a submodule must be stored in that submodule
_as well as any other submodules using that lambda_.

See [github](https://github.com/hashicorp/terraform/issues/12929) for an example and any future fixes.


## Notes on Kinesis Analytics

### Kinesis Analytics Deployment
---

Kinesis Analytics are tricksy beasts and currently the only way to manage them
in some form of version control is with CloudFormation templates.

Unfortunately, CloudFormation does not support automated handling of source AND
storage for lambda functions which are critical to this project, so it is only
used as a last resort.

Sometimes, while trying to test your changes, a CloudFormation stack will break
one way or another and enter the ROLLBACK\_COMPLETE state. When this happens,
there is nothing Terraform can do about it and you must use the AWS console to
delete the stack. _C'est la vie._

*_If you delete the stack, you must go into the console and RUN them again.
Stacks do not run automatically. See `Kinesis Analytics Use` below._*


### Kinesis Analytics Application Code Structure
---

The example module (`alerts/our_project/`) sources the

* SQL code for its analytics application(s)
    * from `alerts/analytics_sql/` in chunks
* CloudFormation stack(s) for its analytics application(s)
    * from `alerts/analytics_stacks/`
    
The code-chunking is due to a limitation of CloudFormation; keeping the code
abstracted in its own file requires passing the code as a CloudFormation
Parameter which has a maximum allowable size of *4096 bytes*. You can, however,
pass multiple parameters and use the `Fn::Join` function.

Example:

```
# cloudformation config in Terraform
resource "aws_cloudformation_stack" "analytics_stack" {
  ...
  parameters {
    ...
    ApplicationCode0  = "${file("${path.module}/../analytics_sql/failures0.sql")}"
    ApplicationCode1  = "${file("${path.module}/../analytics_sql/failures1.sql")}"
    ...
  }
  ...
------
# cloudformation stack
...
Parameters:
  ApplicationCode0:
    Type: String
  ApplicationCode1:
    Type: String
...
      ApplicationCode:
        Fn::Join:
          - ''
          - - Ref: ApplicationCode0
            - Ref: ApplicationCode1
```


### Kinesis Analytics Redeployment
---

If you have a Kinesis Analytics Application up and running and then modify it
(by re-running terraform/cloudformation), you will completely reset any
in-application streams. Beware of this in the case that your in-application
streams are keeping a count of something; the count will reset to 0.


### Kinesis Analytics Use
---

Similar to deployment above, the management of Kinesis Analytics applications
is a bit infantile as of this writing and there is no way to _start_ the
application after you create it other than opening the AWS console, navigating
to your application, and starting it.

## Notes on Route53 and Registered Domains
---

In this repository, there are resources defined for hosted zones in Route53.
Further, there are AWS Certificate Manager resources related to that hosted
zone. However, this only works with a _registered domain_; you will not be able
to request and validate certificates without one.

Additionally: in the REDACTED documentation, it makes no mention of forwarding the
NS records, but you may need to copy the 4 nameservers from Route53 for the
domain you're creating and have them entered into DNS as part of the TT you
create. The hostmaster team member should know what to do.
