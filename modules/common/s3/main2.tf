#Providers

provider "aws" {
  alias  = "mod-s3-us-west-2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "mod-s3-us-east-1"
  region = "us-east-1"
}

#  KMS key for S3 buckets for Guard Duty VPC flow logs 

resource "aws_kms_key" "kms_s3_east_guardduty" {
  provider                = "aws.mod-s3-us-east-2"
  description             = "An S3 bucket encryption for US-WEST: ${var.vpc_name}"
  deletion_window_in_days = 10
}

resource "aws_kms_key" "kms_s3_west_guardduty" {
  provider                = "aws.mod-s3-us-west-2"
  description             = "An S3 bucket encryption for US-EAST: ${var.vpc_name}"
  deletion_window_in_days = 10
}

# The alias name for the Guard Duty KMS key

resource "aws_kms_alias" "kms_s3_alias_east_guarduty" {
  provider      = "aws.mod-s3-us-east-2"
  name          = "alias/${var.vpc_name}-GD-EAST"
  target_key_id = "${aws_kms_key.kms_s3_east_guardduty.key_id}"
}

resource "aws_kms_alias" "kms_s3_alias_west_guarduty" {
  provider      = "aws.mod-s3-us-west-2"
  name          = "alias/${var.vpc_name}-GD-WEST"
  target_key_id = "${aws_kms_key.aws.mod-s3-us-west-2.key_id}"
}

# Provision the S3 buckets for GuardDuty VPC logs 

# US-WEST - This S3 bucket is for the VPC logs storage that can be used later in event of forensics investigations 

resource "aws_s3_bucket" "west_guard_duty_vpc_flowlogs" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${var.environment}-west_guard_duty_vpc_flowlogs"
  acl      = "private"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",
      "Effect": "Deny",
      "Resource": [
        "arn:aws:s3:::ess-${var.ess_env}-bin",
        "arn:aws:s3:::ess-${var.ess_env}-bin/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Principal": "*"
    }
  ]
}
POLICY

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    "${var.glb_tags.billing_core["tagname"]}" = var.glb_tags.billing_core["tagval"]
  }
}

# US-EAST - This S3 bucket is for the VPC logs storage that can be used later in event of forensics investigations 

resource "aws_s3_bucket" "west_guard_duty_vpc_flowlogs" {
  provider = "aws.mod-s3-us-east-2"
  bucket   = "${var.environment}-east"
  # Note: The region argument is no longer valid beginning with the AWS provider v3.0.0, and is now only inherited from
  #       the provider definition. Versions previous to v3.0.0, you could separately specify the region when creating
  #       a new S3 bucket
  #region   = "us-west-2"
  acl      = "private"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",
      "Effect": "Deny",
      "Resource": [
        "arn:aws:s3:::ess-${var.ess_env}-bin",
        "arn:aws:s3:::ess-${var.ess_env}-bin/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Principal": "*"
    }
  ]
}
POLICY

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    "${var.glb_tags.billing_core["tagname"]}" = var.glb_tags.billing_core["tagval"]
  }
}



# ---------------------------------------------------------------------------------------------------------------------
# PROHIBIT PUBLIC ACCESS TO ALL S3 BUCKETS
# ---------------------------------------------------------------------------------------------------------------------

# Update S3 bucket config to block public access
resource "aws_s3_bucket_public_access_block" "s3_ess_bin" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Update S3 bucket config to block public access
resource "aws_s3_bucket_public_access_block" "s3_ess_certs" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_certs.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Update S3 bucket config to block public access
resource "aws_s3_bucket_public_access_block" "s3_ess_config" {
  provider = "aws.mod-s3-us-east-1"
  bucket   = "${aws_s3_bucket.s3_ess_config.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE FOLDERS IN THE S3 BUCKETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_object" "folder_bin_vault" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"
  key    = "vault/"
}

resource "aws_s3_bucket_object" "folder_bin_consul" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"
  key    = "consul/"
}

resource "aws_s3_bucket_object" "folder_bin_packer" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"
  key    = "packer/"
}

resource "aws_s3_bucket_object" "folder_bin_monitor" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"
  key    = "monitor/"
}

resource "aws_s3_bucket_object" "folder_bin_amisrc" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"
  key    = "ami-src/"
}

resource "aws_s3_bucket_object" "folder_bin_envoy" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"
  key    = "envoy/"
}

resource "aws_s3_bucket_object" "folder_bin_ratelimit" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_bin.id}"
  key    = "ratelimit/"
}

resource "aws_s3_bucket_object" "folder_certs_live_app" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_certs.id}"
  key    = "live/app/"
}

resource "aws_s3_bucket_object" "folder_certs_live_repl" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_certs.id}"
  key    = "live/replication/"
}

resource "aws_s3_bucket_object" "folder_certs_live_bevault" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_certs.id}"
  key    = "live/bevault/"
}

#resource "aws_s3_bucket_object" "folder_certs_live_rls" {
#  provider = "aws.mod-s3-us-west-2"
#  bucket   = "${aws_s3_bucket.s3_ess_certs.id}"
#  key    = "live/rls/"
#}

resource "aws_s3_bucket_object" "folder_certs_archive" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_certs.id}"
  key    = "archive/"
}

resource "aws_s3_bucket_object" "folder_certs_intermediates" {
  provider = "aws.mod-s3-us-west-2"
  bucket   = "${aws_s3_bucket.s3_ess_certs.id}"
  key    = "intermediates/"
}

resource "aws_s3_bucket_object" "folder_config_envoy" {
  provider = "aws.mod-s3-us-east-1"
  bucket   = "${aws_s3_bucket.s3_ess_config.id}"
  key    = "envoy/"
}

resource "aws_s3_bucket_object" "folder_config_ratelimit" {
  provider = "aws.mod-s3-us-east-1"
  bucket   = "${aws_s3_bucket.s3_ess_config.id}"
  key    = "ratelimit/"
}
