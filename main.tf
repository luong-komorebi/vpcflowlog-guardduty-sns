#-----------------------------------------------------------------------------------------------------------------------
# Global locals and Data References
#-----------------------------------------------------------------------------------------------------------------------


locals {
  arn_format = "arn:${data.aws_partition.current.partition}"
  enable_cloudwatch         = module.this.enabled && (var.enable_cloudwatch || local.enable_notifications)
  enable_notifications      = module.this.enabled && (var.create_sns_topic || var.findings_notification_arn != null)
  create_sns_topic          = module.this.enabled && var.create_sns_topic
  findings_notification_arn = local.enable_notifications ? (var.findings_notification_arn != null ? var.findings_notification_arn : module.sns_topic[0].sns_topic.arn) : null
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

#-----------------------------------------------------------------------------------------------------------------------
# Pre-requisite - Create KMS and S3 buckets for flow logs to be used with GuardDuty (Use when your ENV does not have flow logs yet)
#-----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "kms" {
  count = module.this.enabled ? 1 : 0

  source_json = var.kms_policy_source_json

  statement {
    sid    = "Enable Root User Permissions"
    effect = "Allow"

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:Tag*",
      "kms:Untag*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "${local.arn_format}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }

  statement {
    sid    = "Allow VPC Flow Logs to use the key"
    effect = "Allow"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = [
      "*"
    ]

    principals {
      type = "Service"

      identifiers = [
        "delivery.logs.amazonaws.com"
      ]
    }
  }
}

module "kms_key" {
  source  = "./modules/common/kms"
  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = join("", data.aws_iam_policy_document.kms.*.json)

  context = module.this.context
}

module "s3_log_storage_bucket" {
  source  = "./modules/common/s3"
  kms_master_key_arn                 = module.kms_key.alias_arn
  sse_algorithm                      = "aws:kms"
  versioning_enabled                 = false
  expiration_days                    = var.expiration_days
  glacier_transition_days            = var.glacier_transition_days
  lifecycle_prefix                   = var.lifecycle_prefix
  lifecycle_rule_enabled             = var.lifecycle_rule_enabled
  lifecycle_tags                     = var.lifecycle_tags
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  noncurrent_version_transition_days = var.noncurrent_version_transition_days
  standard_transition_days           = var.standard_transition_days
  force_destroy                      = var.force_destroy
  bucket_notifications_enabled       = var.bucket_notifications_enabled
  bucket_notifications_type          = var.bucket_notifications_type
  bucket_notifications_prefix        = var.bucket_notifications_prefix
  key_alias_us                       = var.key_alias_us

  context = module.this.context
}

#-----------------------------------------------------------------------------------------------------------------------
# Pre-requisites - Enable Flows logs and send to the new secure bucket (Use when your ENV does not have flow logs yet)
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_flow_log" "default" {
  count                = module.this.enabled && var.flow_log_enabled ? 1 : 0
  log_destination      = module.s3_log_storage_bucket.bucket_arn
  log_destination_type = "s3"
  traffic_type         = var.traffic_type
  vpc_id               = var.vpc_id
}

#-----------------------------------------------------------------------------------------------------------------------
# Subscribe your AWS Acccount to GuardDuty
#-----------------------------------------------------------------------------------------------------------------------

resource "aws_guardduty_detector" "guardduty" {
  enable                       = module.this.enabled
  finding_publishing_frequency = var.finding_publishing_frequency
}

#-----------------------------------------------------------------------------------------------------------------------
# Event Bridge Rules and SNS subscriptions, by default uses EMAIL endpoint 
# Currently there is an error here, possibly acccess control issue because events are not beint sent to SNS
# https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cwe-integration-types.html
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/resource-based-policies-cwe.html#sns-permissions
#-----------------------------------------------------------------------------------------------------------------------


module "sns_topic" {

  source  = "./modules/common/sns-topic"
  count   = local.create_sns_topic ? 1 : 0

  subscribers     = var.subscribers
  sqs_dlq_enabled = false

  attributes = concat(module.this.attributes, ["guardduty"])
  context    = module.this.context
}

module "findings_label" {
  source  = "./modules/common/terraform-null-label"
  attributes = concat(module.this.attributes, ["guardduty", "findings"])
  context    = module.this.context
}

resource "aws_sns_topic_policy" "sns_topic_publish_policy" {
  count  = module.this.enabled && local.create_sns_topic ? 1 : 0
  arn    = local.findings_notification_arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count     = module.this.enabled && local.create_sns_topic ? 1 : 0
  policy_id = "GuardDutyPublishToSNS"
  statement {
    sid = ""
    actions = [
      "sns:Publish"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [module.sns_topic[0].sns_topic.arn]
    effect    = "Allow"
  }
}

resource "aws_cloudwatch_event_rule" "findings" {
  count       = local.enable_cloudwatch == true ? 1 : 0
  name        = module.findings_label.id
  description = "GuardDuty Findings"
  tags        = module.this.tags

  event_pattern = jsonencode(
    {
      "source" : [
        "aws.guardduty"
      ],
      "detail-type" : [
        var.cloudwatch_event_rule_pattern_detail_type
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "imported_findings" {
  count = local.enable_notifications == true ? 1 : 0
  rule  = aws_cloudwatch_event_rule.findings[0].name
  arn   = local.findings_notification_arn
}





