variable "key_alias_us" {
  type        = string
  description = "A short unique key tio append to the auto generated key-alias"
}



variable "lifecycle_prefix" {
  type        = string
  description = "Prefix filter. Used to manage object lifecycle events"
  default     = ""
}

variable "lifecycle_tags" {
  type        = map(string)
  description = "Tags filter. Used to manage object lifecycle events"
  default     = {}
}

variable "force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable"
  default     = false
}

variable "lifecycle_rule_enabled" {
  type        = bool
  description = "Enable lifecycle events on this bucket"
  default     = true
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Specifies when noncurrent object versions expire"
  default     = 90
}

variable "noncurrent_version_transition_days" {
  type        = number
  description = "Specifies when noncurrent object versions transitions"
  default     = 30
}

variable "standard_transition_days" {
  type        = number
  description = "Number of days to persist in the standard storage tier before moving to the infrequent access tier"
  default     = 30
}

variable "glacier_transition_days" {
  type        = number
  description = "Number of days after which to move the data to the glacier storage tier"
  default     = 60
}

variable "expiration_days" {
  type        = number
  description = "Number of days after which to expunge the objects"
  default     = 90
}

variable "traffic_type" {
  type        = string
  description = "The type of traffic to capture. Valid values: `ACCEPT`, `REJECT`, `ALL`"
  default     = "ALL"
}

variable "allow_ssl_requests_only" {
  type        = bool
  default     = true
  description = "Set to `true` to require requests to use Secure Socket Layer (HTTPS/SSL). This will explicitly deny access to HTTP requests"
}

variable "flow_log_enabled" {
  type        = bool
  default     = true
  description = "Enable/disable the Flow Log creation. Useful in multi-account environments where the bucket is in one account, but VPC Flow Logs are in different accounts"
}

variable "kms_policy_source_json" {
  type        = string
  default     = ""
  description = "Additional IAM policy document that can optionally be passed and merged with exported document"
}

variable "bucket_notifications_enabled" {
  type        = bool
  description = "Send notifications for the object created events. Used for 3rd-party log collection from a bucket"
  default     = false
}

variable "bucket_notifications_type" {
  type        = string
  description = "Type of the notification configuration. Only SQS is supported."
  default     = "SQS"
}

variable "bucket_notifications_prefix" {
  type        = string
  description = "Prefix filter. Used to manage object notifications"
  default     = ""
}

variable "enable_cloudwatch" {
  description = <<-DOC
  Flag to indicate whether an CloudWatch logging should be enabled for GuardDuty
  DOC
  type        = bool
}

variable "cloudwatch_event_rule_pattern_detail_type" {
  description = <<-DOC
  The detail-type pattern used to match events that will be sent to SNS.

  For more information, see:
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatchEventsandEventPatterns.html
  https://docs.aws.amazon.com/eventbridge/latest/userguide/event-types.html
  https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_cloudwatch.html
  DOC
  type        = string
  default     = "GuardDuty Finding"
}

variable "create_sns_topic" {
  description = <<-DOC
  Flag to indicate whether an SNS topic should be created for notifications.
  If you want to send findings to a new SNS topic, set this to true and provide a valid configuration for subscribers.
  DOC
  type    = bool
}

variable "subscribers" {
  type = map(object({
    protocol               = string
    endpoint               = string
    endpoint_auto_confirms = bool
    raw_message_delivery   = bool
  }))
  description = <<-DOC
  A map of subscription configurations for SNS topics

  For more information, see:
  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription#argument-reference

  protocol:
    The protocol to use. The possible values for this are: sqs, sms, lambda, application. (http or https are partially
    supported, see link) (email is an option but is unsupported in terraform, see link).
  endpoint:
    The endpoint to send data to, the contents will vary with the protocol. (see link for more information)
  endpoint_auto_confirms:
    Boolean indicating whether the end point is capable of auto confirming subscription e.g., PagerDuty. Default is
    false
  raw_message_delivery:
    Boolean indicating whether or not to enable raw message delivery (the original message is directly passed, not wrapped in JSON with the original message in the message property).
    Default is false
  DOC
  default     =   {
      Email = {
      protocol = "email"
      endpoint = "txsandersfamily@gmail.com"
      raw_message_delivery = false
      endpoint_auto_confirms = false
    }
  }
}

variable "findings_notification_arn" {
  description = <<-DOC
  The ARN for an SNS topic to send findings notifications to. This is only used if create_sns_topic is false.
  If you want to send findings to an existing SNS topic, set the value of this to the ARN of the existing topic and set
  create_sns_topic to false.
  DOC
  default     = null
  type        = string
}

variable "finding_publishing_frequency" {
  description = <<-DOC
  The frequency of notifications sent for finding occurrences. If the detector is a GuardDuty member account, the value
  is determined by the GuardDuty master account and cannot be modified, otherwise it defaults to SIX_HOURS.

  For standalone and GuardDuty master accounts, it must be configured in Terraform to enable drift detection.
  Valid values for standalone and master accounts: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."

  For more information, see:
  https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_cloudwatch.html#guardduty_findings_cloudwatch_notification_frequency
  DOC
  type        = string
  default     = null
}