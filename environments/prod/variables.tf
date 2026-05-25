variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "LinuxAutomation"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Capstone"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access to EC2 instances"
  type        = string
  default     = "10.0.0.0/16"
}

# EC2 Configuration
variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 5
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free tier eligible)"
  type        = string
  default     = "t2.micro" # Free tier: 750 hours per month
}

variable "ami_name_filter" {
  description = "AMI name filter for Amazon Linux 2023"
  type        = string
  default     = "al2023-ami-*-x86_64"
}

# Systems Manager Configuration
variable "ssm_association_schedule" {
  description = "Schedule expression for SSM association (rate or cron)"
  type        = string
  default     = "rate(30 minutes)"
}

variable "inventory_collection_interval" {
  description = "Inventory collection interval in minutes"
  type        = string
  default     = "30"
}

# Patch Manager Configuration
variable "maintenance_window_schedule" {
  description = "Cron expression for maintenance window (UTC)"
  type        = string
  default     = "cron(0 2 ? * SUN *)" # Every Sunday at 2 AM UTC
}

variable "maintenance_window_duration" {
  description = "Duration of maintenance window in hours"
  type        = number
  default     = 2
}

variable "maintenance_window_cutoff" {
  description = "Hours before end of maintenance window to stop scheduling new tasks"
  type        = number
  default     = 1
}

variable "patch_classification" {
  description = "Patch classifications to install"
  type        = list(string)
  default     = ["Security", "Bugfix", "Enhancement"]
}

variable "patch_severity" {
  description = "Patch severity levels to install"
  type        = list(string)
  default     = ["Critical", "Important", "Medium"]
}

# ALB Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 2
}

# S3 Configuration
variable "log_retention_days" {
  description = "Number of days to retain logs in S3 (Free tier: 5 GB storage)"
  type        = number
  default     = 30 # Reduced for free tier
}

variable "enable_s3_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

# CloudWatch Configuration
variable "log_retention_in_days" {
  description = "CloudWatch log retention in days (Free tier: 5 GB ingestion, 10 metrics, 10 alarms)"
  type        = number
  default     = 7 # Reduced for free tier to minimize storage
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
