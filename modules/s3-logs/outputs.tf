output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.ssm_logs.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.ssm_logs.arn
}

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.ssm_logs.id
}

output "bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.ssm_logs.region
}
