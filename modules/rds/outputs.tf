# Universal RDS Module Outputs

# Common Outputs
output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "parameter_group_name" {
  description = "The name of the parameter group"
  value       = var.use_aurora ? (length(aws_rds_cluster_parameter_group.aurora) > 0 ? aws_rds_cluster_parameter_group.aurora[0].name : "") : (length(aws_db_parameter_group.rds) > 0 ? aws_db_parameter_group.rds[0].name : "")
}

# Aurora-specific Outputs
output "aurora_cluster_id" {
  description = "The ID of the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].id : null
}

output "aurora_cluster_endpoint" {
  description = "The cluster endpoint for Aurora (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "The reader endpoint for Aurora (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

output "aurora_cluster_arn" {
  description = "The ARN of the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].arn : null
}

output "aurora_cluster_resource_id" {
  description = "The resource ID of the Aurora cluster (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].cluster_resource_id : null
}

output "aurora_writer_instance_id" {
  description = "The ID of the Aurora writer instance (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster_instance.aurora_writer[0].id : null
}

output "aurora_reader_instance_ids" {
  description = "The IDs of Aurora reader instances (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster_instance.aurora_readers[*].id : []
}

# RDS-specific Outputs
output "rds_instance_id" {
  description = "The ID of the RDS instance (only for regular RDS)"
  value       = var.use_aurora ? null : aws_db_instance.rds[0].id
}

output "rds_instance_endpoint" {
  description = "The endpoint of the RDS instance (only for regular RDS)"
  value       = var.use_aurora ? null : aws_db_instance.rds[0].endpoint
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance (only for regular RDS)"
  value       = var.use_aurora ? null : aws_db_instance.rds[0].arn
}

output "rds_instance_resource_id" {
  description = "The resource ID of the RDS instance (only for regular RDS)"
  value       = var.use_aurora ? null : aws_db_instance.rds[0].resource_id
}

# Universal Outputs (works for both Aurora and RDS)
output "endpoint" {
  description = "The primary database endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.rds[0].endpoint
}

output "port" {
  description = "The database port"
  value       = var.port
}

output "database_name" {
  description = "The name of the database"
  value       = var.database_name
}

output "master_username" {
  description = "The master username"
  value       = var.master_username
  sensitive   = true
}

output "engine" {
  description = "The database engine"
  value       = var.engine
}

output "engine_version" {
  description = "The database engine version"
  value       = var.engine_version
}

output "connection_info" {
  description = "Database connection information"
  value = {
    endpoint      = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.rds[0].endpoint
    port         = var.port
    database_name = var.database_name
    username     = var.master_username
    engine       = var.engine
    type         = var.use_aurora ? "aurora" : "rds"
  }
  sensitive = true
}