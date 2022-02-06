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
* Due to the use of count and for each dynamic code blocks, the old code concatenated ARN strings with name.*.id pattern
* In recent versions the use of .id is no longer needed in replace of ARN attribute
* Additionally, the [0] index is passed with every name[0] in replace of name.*.id
* The root main S3 bucket policies have been removed and pushed to modules s3 main.tf to cleanup root main.tf
* Some of the default bucket ACL policies have been removed, only enforced TLS and Public block is enabled
* SNS ACL access rules updated to accept eventbridge as a principle service writing into topic
* The KMS key alias is not s user supplied input, previously a validation error was being thrown because of the use of name.*.id concatenation
* Enable SNS and Cloud Event is now user supplied input excepting bool: true:false
* VPCid is now a user supplied input expecting the vpc-foobaripsum format
* All reference to external registries have been removed to prevent supply chain attack
* All source = /registry keys removed to support local paths and version references removed to support local path files


https://securitysandman.com/

## Tuning the CloudWatch event rule 

* Currently the rule detects and forward all Guard Duty findings. However this can be tuned up or down by updating the rule as follows 

'

{
  "source": [
    "aws.guardduty"
  ],
  "detail-type": [
    "GuardDuty Finding"
  ],
  "detail": {
    "severity": [
      4,
      4.0,
      4.1,
      4.2,
      4.3,
      4.4,
      4.5,
      4.6,
      4.7,
      4.8,
      4.9,
      5,
      5.0,
      5.1,
      5.2,
      5.3,
      5.4,
      5.5,
      5.6,
      5.7,
      5.8,
      5.9,
      6,
      6.0,
      6.1,
      6.2,
      6.3,
      6.4,
      6.5,
      6.6,
      6.7,
      6.8,
      6.9,
      7,
      7.0,
      7.1,
      7.2,
      7.3,
      7.4,
      7.5,
      7.6,
      7.7,
      7.8,
      7.9,
      8,
      8.0,
      8.1,
      8.2,
      8.3,
      8.4,
      8.5,
      8.6,
      8.7,
      8.8,
      8.9
    ]
  }
}

'

## Known Bugs 

* Currently, the SNS EMAIL endpoint resource is configured and works in standalone. However, a successful GuardDuty CloudWatch notification has not been tested successfully. Possibly the shif tto EventBridge causing an ACL permissions error here. need more time to generate events and trigger the SNS tests. 

## GuardDuty findings

https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-active.html

