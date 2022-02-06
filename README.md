# Guard Duty and VPC flow logs, s3 and kms 

The following repo is a set of terraform scripts intended to enable Guard Duty for a specific region in which Terraform is executed within. The code assumes you have already provisioned a VPC but have yet to enable flow logs on it. The code then proceeds with the folllowing 

The code bahaves as follows 

* 1.) Creates and AWS KMS for the s3 bucket that will store the vpc flow logs
* 2.) Creates TLS only and non-public S3 bucket bucket encrypted with the new KMS key 
* 3.) Configures the flow logs to send to the new s3 bucket 
* 4.) Creates an SNS topic for Guard Duty events to be sent to 
* 5.) Creates a CloudWatch/EventBridge rule to parse Guard Duty findings and forward them to SNS
* 6.) Enables GuardDuty in the region in which you execute the Terraform script

## About the refactor  

The code is a refactored version of the upstream cloud posse source code under Apache 2.0 license. However, the code was refactored and modified as follows

* Most importantly the previous code did not work correctly on Terraform v1.1.5
* Due to the use of count and for each dynmaic code blocks, the old code concatinated ARN strings with name.*.id pattern
* In recent versions the use of .id is no longer needed in replace of ARN attribute
* Additonally, the [0] index is passed with every name[0] in replace of name.*.id
* The root main S3 bucket policies have been removed and pushed to modules s3 main.tf to cleanup root main.tf 
* Some of the default bucket ACL policies have been removed, only enforced TLS and Public block is enabled 
* SNS ACL access rules updated to accept eventbridge as a princaple service writing into topic  
* The KMS key alias is not s user supplied input, previously a validation error was being thrown because of the use of name.*.id concatination 
* Enable SNS and Cloud Event is now user supplied input excepting bool: true:false
* VPCid is now a user supplied input expecting the vpc-foobaripsum format 
* All reference to external registries have been removed to prevent supply chain attack 
* All source = /registry keys removed to support local paths and version references removed to support local path files 


https://securitysandman.com/

## Bugs 

* Currently, the SNS EMAIL endpoint resource is configured and works in standalone. However, a successful GuardDuty CloudWatch notification has not been tested successfully. Possibly the shif tto EventBridge causing an ACL permissions error here. need more time to generate events and trigger the SNS tests. 
* 



