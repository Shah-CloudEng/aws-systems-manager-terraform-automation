output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.web_servers[*].id
}

output "instance_arns" {
  description = "List of EC2 instance ARNs"
  value       = aws_instance.web_servers[*].arn
}

output "private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.web_servers[*].private_ip
}

output "availability_zones" {
  description = "List of availability zones"
  value       = aws_instance.web_servers[*].availability_zone
}
