output "association_id" {
  description = "ID of the inventory association"
  value       = aws_ssm_association.inventory.association_id
}

output "association_name" {
  description = "Name of the inventory association"
  value       = aws_ssm_association.inventory.association_name
}
