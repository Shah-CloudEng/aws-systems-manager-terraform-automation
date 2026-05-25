# Data source for current account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 Bucket for SSM and operational logs
resource "aws_s3_bucket" "ssm_logs" {
  bucket = lower("${var.project_name}-${var.environment}-ssm-logs-${data.aws_caller_identity.current.account_id}")

  tags = {
    Name        = "${var.project_name}-${var.environment}-SSM-Logs"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "LogStorage"
  }

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy for log retention
resource "aws_s3_bucket_lifecycle_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER_IR"
    }
  }
}

# Bucket policy for SSM and ALB access
resource "aws_s3_bucket_policy" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  policy = data.aws_iam_policy_document.ssm_logs_policy.json
}

data "aws_iam_policy_document" "ssm_logs_policy" {
  # Allow SSM to write logs
  statement {
    sid    = "AllowSSMToWriteLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "${aws_s3_bucket.ssm_logs.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Allow ALB to write access logs (if enabled)
  statement {
    sid    = "AllowALBToWriteLogs"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.elb_service_account}:root"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.ssm_logs.arn}/alb-access-logs/*"
    ]
  }

  statement {
    sid    = "AllowALBToGetBucketACL"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticloadbalancing.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      aws_s3_bucket.ssm_logs.arn
    ]
  }

  # Deny insecure transport
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.ssm_logs.arn,
      "${aws_s3_bucket.ssm_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ELB service account mapping for ALB logs
locals {
  # ELB service account IDs per region
  elb_service_accounts = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    eu-west-1      = "156460612806"
    eu-central-1   = "054676820928"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-northeast-1 = "582318560864"
    sa-east-1      = "507241528517"
  }

  elb_service_account = lookup(
    local.elb_service_accounts,
    data.aws_region.current.name,
    "127311923021" # Default to us-east-1
  )
}

# S3 bucket notification (optional - for Lambda triggers)
# Uncomment if you want to process logs with Lambda

# resource "aws_s3_bucket_notification" "ssm_logs_notification" {
#   bucket = aws_s3_bucket.ssm_logs.id
#
#   lambda_function {
#     lambda_function_arn = var.log_processor_lambda_arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = "ssm-associations/"
#   }
# }
