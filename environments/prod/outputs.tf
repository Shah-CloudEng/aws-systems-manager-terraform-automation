output "vpc_id" {
  description = "VPC ID being used"
  value       = var.existing_vpc_id
}

output "iam_role_name" {
  description = "IAM role name for Systems Manager"
  value       = module.iam_ssm.role_name
}

output "iam_role_arn" {
  description = "IAM role ARN for Systems Manager"
  value       = module.iam_ssm.role_arn
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = module.iam_ssm.instance_profile_name
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security_groups.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = module.security_groups.ec2_security_group_id
}

output "ec2_instance_ids" {
  description = "List of EC2 instance IDs"
  value       = module.ec2_fleet.instance_ids
}

output "ec2_private_ips" {
  description = "List of EC2 private IP addresses"
  value       = module.ec2_fleet.private_ips
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_group_arn
}

output "ssm_document_name" {
  description = "Name of the SSM document for Apache installation"
  value       = module.systems_manager.document_name
}

output "ssm_association_id" {
  description = "ID of the SSM association"
  value       = module.systems_manager.association_id
}

output "patch_baseline_id" {
  description = "ID of the patch baseline"
  value       = module.patch_manager.patch_baseline_id
}

output "maintenance_window_id" {
  description = "ID of the maintenance window"
  value       = module.patch_manager.maintenance_window_id
}

output "inventory_association_id" {
  description = "ID of the inventory association"
  value       = module.inventory.association_id
}

output "s3_logs_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = module.s3_logs.bucket_name
}

output "s3_logs_bucket_arn" {
  description = "ARN of the S3 bucket for logs"
  value       = module.s3_logs.bucket_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.cloudwatch.log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.cloudwatch.log_group_arn
}

# Helpful outputs for verification
output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "fleet_manager_console" {
  description = "AWS Systems Manager Fleet Manager console URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/systems-manager/managed-instances?region=${var.aws_region}"
}

output "patch_manager_console" {
  description = "AWS Systems Manager Patch Manager console URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/systems-manager/patch-manager?region=${var.aws_region}"
}

output "inventory_console" {
  description = "AWS Systems Manager Inventory console URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/systems-manager/inventory?region=${var.aws_region}"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    region             = var.aws_region
    environment        = var.environment
    instance_count     = var.instance_count
    application_url    = "http://${module.alb.alb_dns_name}"
    ssm_managed        = true
    patch_mgmt_enabled = true
    inventory_enabled  = true
    logging_enabled    = true
    monitoring_enabled = true
  }
}
