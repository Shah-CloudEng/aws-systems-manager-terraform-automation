variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "collection_interval" {
  description = "Inventory collection interval in minutes"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket for inventory data"
  type        = string
}
