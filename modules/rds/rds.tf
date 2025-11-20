# Regular RDS Instance resources

# Parameter Group for regular RDS
resource "aws_db_parameter_group" "rds" {
  count  = var.use_aurora ? 0 : 1
  family = var.parameter_group_family
  name   = "${var.project_name}-${var.environment}-rds-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-rds-params"
      Environment = var.environment
      Module      = "rds"
    }
  )
}

# Regular RDS Instance
resource "aws_db_instance" "rds" {
  count = var.use_aurora ? 0 : 1
  
  identifier = "${var.project_name}-${var.environment}-rds"
  
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id          = var.kms_key_id
  
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.port
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.rds[0].name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  multi_az               = var.multi_az
  publicly_accessible    = var.publicly_accessible
  
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-rds-final-snapshot"
  
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  deletion_protection            = var.deletion_protection
  
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval
  monitoring_role_arn        = var.monitoring_role_arn
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-rds"
      Environment = var.environment
      Module      = "rds"
    }
  )
}