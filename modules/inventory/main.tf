# SSM Association for Inventory Collection
resource "aws_ssm_association" "inventory" {
  name             = "AWS-GatherSoftwareInventory"
  association_name = "${var.project_name}-${var.environment}-Inventory-Collection"

  # Target instances by tag
  targets {
    key    = "tag:Project"
    values = [var.project_name]
  }

  # Schedule for inventory collection
  schedule_expression = "rate(${var.collection_interval} minutes)"

  # S3 output location
  output_location {
    s3_bucket_name = var.s3_bucket_name
    s3_key_prefix  = "ssm-inventory"
  }

  # Inventory collection parameters
  parameters = {
    applications                = ["Enabled"]
    awsComponents               = ["Enabled"]
    networkConfig               = ["Enabled"]
    services                    = ["Enabled"]
    instanceDetailedInformation = ["Enabled"]
    windowsUpdates              = ["Disabled"]
    windowsRoles                = ["Disabled"]
    windowsRegistry             = [""]
    customInventory             = [""]
    files                       = [""]
  }

  # Compliance severity
  compliance_severity = "MEDIUM"

  tags = {
    Name        = "${var.project_name}-${var.environment}-Inventory-Collection"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "InventoryManagement"
  }
}

# Resource Data Sync for centralized inventory
resource "aws_ssm_resource_data_sync" "inventory_sync" {
  name = "${var.project_name}-${var.environment}-Inventory-Sync"

  s3_destination {
    bucket_name = var.s3_bucket_name
    prefix      = "ssm-resource-data-sync"
    region      = data.aws_region.current.name
  }
}

# Data source for current region
data "aws_region" "current" {}
