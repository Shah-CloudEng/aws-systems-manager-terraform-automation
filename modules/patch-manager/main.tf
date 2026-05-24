# SSM Patch Baseline for Amazon Linux
resource "aws_ssm_patch_baseline" "amazon_linux" {
  name             = "${var.project_name}-${var.environment}-AmazonLinux-Baseline"
  description      = "Patch baseline for Amazon Linux 2023 instances"
  operating_system = "AMAZON_LINUX_2023"

  # Approval rules for patches
  approval_rule {
    approve_after_days = 7
    compliance_level   = "HIGH"

    patch_filter {
      key    = "CLASSIFICATION"
      values = var.patch_classification
    }

    patch_filter {
      key    = "SEVERITY"
      values = var.patch_severity
    }

    enable_non_security = true
  }

  # Auto-approve critical security patches immediately
  approval_rule {
    approve_after_days = 0
    compliance_level   = "CRITICAL"

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-AmazonLinux-Baseline"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "PatchManagement"
  }
}

# Register patch baseline as default for Amazon Linux 2023
resource "aws_ssm_patch_baseline" "default_baseline" {
  name             = "${var.project_name}-${var.environment}-Default-Baseline"
  description      = "Default patch baseline for the project"
  operating_system = "AMAZON_LINUX_2023"

  approval_rule {
    approve_after_days = 7

    patch_filter {
      key    = "CLASSIFICATION"
      values = var.patch_classification
    }

    patch_filter {
      key    = "SEVERITY"
      values = var.patch_severity
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-Default-Baseline"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Maintenance Window for patching
resource "aws_ssm_maintenance_window" "patch_window" {
  name              = "${var.project_name}-${var.environment}-Patch-Window"
  description       = "Maintenance window for system patching"
  schedule          = var.maintenance_window_schedule
  duration          = var.maintenance_window_duration
  cutoff            = var.maintenance_window_cutoff
  schedule_timezone = "UTC"
  enabled           = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-Patch-Window"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "PatchManagement"
  }
}

# Maintenance Window Target - tag-based targeting
resource "aws_ssm_maintenance_window_target" "patch_targets" {
  window_id     = aws_ssm_maintenance_window.patch_window.id
  name          = "${var.project_name}-PatchTargets"
  description   = "EC2 instances targeted for patching"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Project"
    values = [var.project_name]
  }

  targets {
    key    = "tag:Environment"
    values = [var.environment]
  }
}

# Maintenance Window Task - Run patch scan and install
resource "aws_ssm_maintenance_window_task" "patch_task" {
  window_id        = aws_ssm_maintenance_window.patch_window.id
  name             = "${var.project_name}-PatchTask"
  description      = "Scan and install patches on target instances"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.ssm_maintenance_window.arn
  max_concurrency  = "50%"
  max_errors       = "0"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_targets.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket_name
      output_s3_key_prefix = "patch-manager/patch-logs"
      service_role_arn     = aws_iam_role.ssm_maintenance_window.arn
      timeout_seconds      = 3600

      cloudwatch_config {
        cloudwatch_log_group_name = var.cloudwatch_log_group
        cloudwatch_output_enabled = true
      }

      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}

# IAM Role for Maintenance Window
resource "aws_iam_role" "ssm_maintenance_window" {
  name               = "${var.project_name}-SSM-MaintenanceWindow-Role"
  description        = "IAM role for SSM Maintenance Window execution"
  assume_role_policy = data.aws_iam_policy_document.ssm_maintenance_assume.json

  tags = {
    Name        = "${var.project_name}-SSM-MaintenanceWindow-Role"
    Project     = var.project_name
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "ssm_maintenance_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Attach policy for SSM execution
resource "aws_iam_role_policy_attachment" "ssm_maintenance_policy" {
  role       = aws_iam_role.ssm_maintenance_window.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

# Custom policy for S3 and CloudWatch access
resource "aws_iam_role_policy" "ssm_maintenance_custom" {
  name   = "SSM-Maintenance-Custom-Policy"
  role   = aws_iam_role.ssm_maintenance_window.id
  policy = data.aws_iam_policy_document.ssm_maintenance_custom.json
}

data "aws_iam_policy_document" "ssm_maintenance_custom" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:${var.cloudwatch_log_group}:*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:SendCommand",
      "ssm:GetCommandInvocation"
    ]

    resources = ["*"]
  }
}

# Patch Group association
resource "aws_ssm_patch_group" "web_servers" {
  baseline_id = aws_ssm_patch_baseline.amazon_linux.id
  patch_group = "${var.project_name}-WebServers"
}
