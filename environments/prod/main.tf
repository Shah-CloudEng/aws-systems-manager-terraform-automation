# Data source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Custom VPC with public subnets (ALB) and private subnets (EC2)
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# IAM Role and Instance Profile for Systems Manager
module "iam_ssm" {
  source = "../../modules/iam-ssm"

  project_name = var.project_name
  environment  = var.environment
}

# Security Groups for ALB and EC2
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id           = module.vpc.vpc_id
  project_name     = var.project_name
  environment      = var.environment
  allowed_ssh_cidr = var.allowed_ssh_cidr

  depends_on = [module.vpc]
}

# EC2 Fleet (5 instances with SSM) — placed in private subnets
module "ec2_fleet" {
  source = "../../modules/ec2-fleet"

  instance_count            = var.instance_count
  instance_type             = var.instance_type
  ami_id                    = data.aws_ami.amazon_linux_2023.id
  subnet_ids                = module.vpc.private_subnet_ids
  security_group_ids        = [module.security_groups.ec2_security_group_id]
  iam_instance_profile_name = module.iam_ssm.instance_profile_name
  project_name              = var.project_name
  environment               = var.environment

  depends_on = [module.iam_ssm, module.vpc]
}

# S3 Bucket for Logs
module "s3_logs" {
  source = "../../modules/s3-logs"

  project_name       = var.project_name
  environment        = var.environment
  log_retention_days = var.log_retention_days
  enable_versioning  = var.enable_s3_versioning
}

# CloudWatch Log Group
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name          = var.project_name
  environment           = var.environment
  log_retention_in_days = var.log_retention_in_days
}

# Systems Manager - Apache Installation via SSM
module "systems_manager" {
  source = "../../modules/systems-manager"

  project_name         = var.project_name
  environment          = var.environment
  s3_bucket_name       = module.s3_logs.bucket_name
  cloudwatch_log_group = module.cloudwatch.log_group_name
  association_schedule = var.ssm_association_schedule

  depends_on = [
    module.ec2_fleet,
    module.s3_logs,
    module.cloudwatch
  ]
}

# Patch Manager Configuration
module "patch_manager" {
  source = "../../modules/patch-manager"

  project_name                = var.project_name
  environment                 = var.environment
  maintenance_window_schedule = var.maintenance_window_schedule
  maintenance_window_duration = var.maintenance_window_duration
  maintenance_window_cutoff   = var.maintenance_window_cutoff
  patch_classification        = var.patch_classification
  patch_severity              = var.patch_severity
  s3_bucket_name              = module.s3_logs.bucket_name
  cloudwatch_log_group        = module.cloudwatch.log_group_name

  depends_on = [
    module.ec2_fleet,
    module.s3_logs,
    module.cloudwatch
  ]
}

# Inventory Configuration
module "inventory" {
  source = "../../modules/inventory"

  project_name        = var.project_name
  environment         = var.environment
  collection_interval = var.inventory_collection_interval
  s3_bucket_name      = module.s3_logs.bucket_name

  depends_on = [
    module.ec2_fleet,
    module.s3_logs
  ]
}

# Application Load Balancer — placed in public subnets, routes to EC2 in private subnets
module "alb" {
  source = "../../modules/alb"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  security_group_ids         = [module.security_groups.alb_security_group_id]
  instance_count             = var.instance_count
  instance_ids               = module.ec2_fleet.instance_ids
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.alb_idle_timeout
  health_check_path          = var.health_check_path
  health_check_interval      = var.health_check_interval
  health_check_timeout       = var.health_check_timeout
  healthy_threshold          = var.healthy_threshold
  unhealthy_threshold        = var.unhealthy_threshold
  s3_logs_bucket             = module.s3_logs.bucket_name

  depends_on = [
    module.ec2_fleet,
    module.security_groups,
    module.s3_logs,
    module.vpc
  ]
}
