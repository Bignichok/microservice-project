output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
}
