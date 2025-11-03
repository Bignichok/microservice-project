output "s3_backend_info" {
  description = "Information about S3 bucket and DynamoDB table"
  value = {
    s3_bucket_name       = module.s3_backend.s3_bucket_name
    s3_bucket_arn        = module.s3_backend.s3_bucket_arn
    dynamodb_table_name  = module.s3_backend.dynamodb_table_name
    dynamodb_table_arn   = module.s3_backend.dynamodb_table_arn
  }
}

output "vpc_info" {
  description = "Information about VPC and subnets"
  value = {
    vpc_id              = module.vpc.vpc_id
    vpc_cidr_block      = module.vpc.vpc_cidr_block
    public_subnet_ids   = module.vpc.public_subnet_ids
    private_subnet_ids  = module.vpc.private_subnet_ids
    internet_gateway_id = module.vpc.internet_gateway_id
    nat_gateway_ids     = module.vpc.nat_gateway_ids
  }
}

output "ecr_info" {
  description = "Information about ECR repository"
  value = {
    repository_name = module.ecr.repository_name
    repository_url  = module.ecr.repository_url
    repository_arn  = module.ecr.repository_arn
  }
}
