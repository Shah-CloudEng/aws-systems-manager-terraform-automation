# IAM Role for EC2 Systems Manager
resource "aws_iam_role" "ssm_role" {
  name               = "EC2-SSM-WebServer-Role"
  description        = "IAM role for EC2 instances to use AWS Systems Manager"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "EC2-SSM-WebServer-Role"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "SystemsManager"
  }
}

# EC2 Trust Relationship
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Attach AWS Managed Policy for Systems Manager
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Additional policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom inline policy for S3 log uploads
resource "aws_iam_role_policy" "s3_ssm_logs" {
  name   = "SSM-S3-Logs-Policy"
  role   = aws_iam_role.ssm_role.id
  policy = data.aws_iam_policy_document.s3_ssm_logs.json
}

data "aws_iam_policy_document" "s3_ssm_logs" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::*-ssm-logs-*",
      "arn:aws:s3:::*-ssm-logs-*/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetEncryptionConfiguration"
    ]

    resources = ["*"]
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "EC2-SSM-WebServer-Profile"
  role = aws_iam_role.ssm_role.name

  tags = {
    Name        = "EC2-SSM-WebServer-Profile"
    Project     = var.project_name
    Environment = var.environment
  }
}
