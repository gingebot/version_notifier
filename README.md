# Version Notifier

Welcome to the imaginatively named Version Notifier, this application is designed to monitor applications and notify users when new releases of an application is available.

Currently version notifier monitors Terraform only, however it is built with a dynamic modular plugin architecture in mind so is relatively simple to add new applications to monitor as required.

# Overview
## Preamble

This application is a delve into AWS, Serverless and IAC, built and designed for education purposes rather than a real need, there's no better way to learn than to do!

Don't knock my python skills, my focus has been on IAC and serverless, rather than robust python, who needs to catch exceptions anyway..... :p

## Technologies Employed

 - Terraform
 - Python
 - AWS
	 - Lambda
	 - Dynamodb
	 - Simple Notification Service
	 - Eventbridge
	 - IAM

## AWS Resources Overview
**Lambda:  new_version_notifier**
This is the glue that get invoked by dynamoDB stream when a new change is written to the DB, it sends the new data to the SNS topic to distribute to recipients.

**Lambda: check_package_terraform**
This is the python code that checks the Terraform releases page and if it finds a new release writes the release details to DynamoDB, the Lambda is invoked by a periodic Eventbridge rule.

**EventBridge Rule: check_version**
This is the rule that invokes the check lambda daily.

**DynamoBD table package_version**
This table holds the package version data, it is updated by the check_package lambda. It is also configured with a dynamoDB stream which invokes the new_version_notifier Lambda function when changes occur.

**SNS Topic package-update**
This is the SNS topic that posts details of package updates to recipients; a summary to SMS and a more verbose version to email.

# Notification example
This is a typical email notification generated by the application, SMS notifications are similar, just the release notes are omitted.
> Subject: New Package Release: terraform - v1.3.2
Package: terraform  
Version: 1.3.2  
Update Type: patch  
Release Notes Url: [https://raw.githubusercontent.com/hashicorp/terraform/v1.3/CHANGELOG.md](https://raw.githubusercontent.com/hashicorp/terraform/v1.3/CHANGELOG.md)  
Release notes:  
> 
> ## 1.3.2 (October 06, 2022)      BUG FIXES:     
> * Fixed a crash caused by Terraform incorrectly re-registering output value preconditions during the apply phase (rather than just reusing
> the already-planned checks from the plan phase).
> ([#31890]([https://github.com/hashicorp/terraform/issues/31890](https://github.com/hashicorp/terraform/issues/31890)))
> 
> * Prevent errors when the provider reports that a deposed instance no longer exists
> ([#31902]([https://github.com/hashicorp/terraform/issues/31902](https://github.com/hashicorp/terraform/issues/31902)))
> 
> * Using `ignore_changes = all` could cause persistent diffs with legacy providers
> ([#31914]([https://github.com/hashicorp/terraform/issues/31914](https://github.com/hashicorp/terraform/issues/31914)))
> 
> * Fix cycles when resource dependencies cross over between independent provider configurations
> ([#31917]([https://github.com/hashicorp/terraform/issues/31917](https://github.com/hashicorp/terraform/issues/31917)))
> 
> * Improve handling of missing resource instances during `import` ([#31878]([https://github.com/hashicorp/terraform/issues/31878](https://github.com/hashicorp/terraform/issues/31878)))

# Usage

## Basic Usage
Feel free to simply apply the Terraform, it will build all resources, you can then manually added subscriptions to the SNS topic (both email and mobile phone) and you'll start getting notifications when new versions of Terraform are released.


## Advanced Usage

When applying the Terraform, you can provide the following variables, which pretty self explanatory:

     variable "dynamo_table" {
      type        = string
      description = "Name of the Dynamo DB table"
      default     = "package_version"
    }
    variable "notify_email" {
      type        = set(string)
      description = "Set of email addresses to be notified when a new release occurs"
      default = []
    }
    variable "notify_sms" {
      type        = set(string)
      description = "Set a mobile numbers to be notified by test when a new release occurs"
      default = []
    }
    variable "release_offset" {
      type        = number
      description = "release offset in case someone wants to monitor n-x releases"
      default = 0
    }

# Modular Design / Extension
It is possible to drop in your own lambda code to monitor another package and the application should dynamically create all the resources required (I say should as I have not tested it yet!).

In the directory *lambdas/checks* create a sub-directory the name of the package you want to check (for instance erlang).

Within this directory, there must be 2 files:

**requirements.txt**
a pip requirements format file of any external libraries used

**main.py**
This should be a python 3.9 script
### main.py specification
- python 3.9 compatible.
- The following environment variables are made available:
	- DYNAMO_TABLE - this is the name of the table to write to
	- RELEASE_OFFSET - this is the offset of release you wish to monitor and notify on (in case you don't want the system to notify you on the latest release)
- The entrypoint function should be **lambda_handler(event, context)** however event and context will be empty variables.
- The script should write to the DYNAMO_TABLE with the following keys:
	- Package
	- Version
	- ReleaseNotes
	- Url
	- Updatetype
- The script should read from DYNAMO_TABLE using the key *Package* to retrieve the last version record to use as a comparison. 
