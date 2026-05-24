variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for command outputs"
  type        = string
}

variable "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  type        = string
}

variable "association_schedule" {
  description = "Schedule for SSM association"
  type        = string
  default     = "rate(30 minutes)"
}
