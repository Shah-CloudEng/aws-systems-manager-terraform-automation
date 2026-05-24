variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "maintenance_window_schedule" {
  description = "Cron expression for maintenance window"
  type        = string
}

variable "maintenance_window_duration" {
  description = "Duration of maintenance window in hours"
  type        = number
}

variable "maintenance_window_cutoff" {
  description = "Hours before end to stop scheduling new tasks"
  type        = number
}

variable "patch_classification" {
  description = "Patch classifications to install"
  type        = list(string)
}

variable "patch_severity" {
  description = "Patch severity levels to install"
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "S3 bucket for patch logs"
  type        = string
}

variable "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  type        = string
}
