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
    applications = jsonencode([
      {
        parameterName  = "applications"
        parameterValue = "Enabled"
      }
    ])

    awsComponents = jsonencode([
      {
        parameterName  = "awsComponents"
        parameterValue = "Enabled"
      }
    ])

    files = jsonencode([
      {
        parameterName  = "files"
        parameterValue = ""
      }
    ])

    networkConfig = jsonencode([
      {
        parameterName  = "networkConfig"
        parameterValue = "Enabled"
      }
    ])

    services = jsonencode([
      {
        parameterName  = "services"
        parameterValue = "Enabled"
      }
    ])

    windowsUpdates = jsonencode([
      {
        parameterName  = "windowsUpdates"
        parameterValue = "Disabled"
      }
    ])

    instanceDetailedInformation = jsonencode([
      {
        parameterName  = "instanceDetailedInformation"
        parameterValue = "Enabled"
      }
    ])

    windowsRegistry = jsonencode([
      {
        parameterName  = "windowsRegistry"
        parameterValue = ""
      }
    ])

    windowsRoles = jsonencode([
      {
        parameterName  = "windowsRoles"
        parameterValue = "Disabled"
      }
    ])

    customInventory = jsonencode([
      {
        parameterName  = "customInventory"
        parameterValue = ""
      }
    ])
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
