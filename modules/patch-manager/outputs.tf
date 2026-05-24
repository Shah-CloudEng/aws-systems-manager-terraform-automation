output "patch_baseline_id" {
  description = "ID of the patch baseline"
  value       = aws_ssm_patch_baseline.amazon_linux.id
}

output "patch_baseline_arn" {
  description = "ARN of the patch baseline"
  value       = aws_ssm_patch_baseline.amazon_linux.arn
}

output "maintenance_window_id" {
  description = "ID of the maintenance window"
  value       = aws_ssm_maintenance_window.patch_window.id
}

output "maintenance_window_target_id" {
  description = "ID of the maintenance window target"
  value       = aws_ssm_maintenance_window_target.patch_targets.id
}

output "maintenance_window_task_id" {
  description = "ID of the maintenance window task"
  value       = aws_ssm_maintenance_window_task.patch_task.id
}
