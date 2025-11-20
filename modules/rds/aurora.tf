# Aurora Cluster resources

# Parameter Group for Aurora
resource "aws_rds_cluster_parameter_group" "aurora" {
  count  = var.use_aurora ? 1 : 0
  family = var.parameter_group_family
  name   = "${var.project_name}-${var.environment}-aurora-cluster-params"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-aurora-cluster-params"
      Environment = var.environment
      Module      = "rds"
    }
  )
}

# Aurora Cluster
resource "aws_rds_cluster" "aurora" {
  count = var.use_aurora ? 1 : 0
  
  cluster_identifier     = "${var.project_name}-${var.environment}-aurora"
  engine                = var.engine
  engine_version        = var.engine_version
  database_name         = var.database_name
  master_username       = var.master_username
  master_password       = var.master_password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora[0].name
  
  storage_encrypted = var.storage_encrypted
  kms_key_id       = var.kms_key_id
  
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-aurora-final-snapshot"
  
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  deletion_protection            = var.deletion_protection
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-aurora"
      Environment = var.environment
      Module      = "rds"
    }
  )
}

# Aurora Cluster Instance (Writer)
resource "aws_rds_cluster_instance" "aurora_writer" {
  count = var.use_aurora ? 1 : 0
  
  identifier         = "${var.project_name}-${var.environment}-aurora-writer"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version
  
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval
  monitoring_role_arn        = var.monitoring_role_arn
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-aurora-writer"
      Environment = var.environment
      Module      = "rds"
      Role        = "writer"
    }
  )
}

# Aurora Cluster Reader Instances (optional)
resource "aws_rds_cluster_instance" "aurora_readers" {
  count = var.use_aurora ? var.reader_count : 0
  
  identifier         = "${var.project_name}-${var.environment}-aurora-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = var.reader_instance_class != "" ? var.reader_instance_class : var.instance_class
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version
  
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval
  monitoring_role_arn        = var.monitoring_role_arn
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-aurora-reader-${count.index + 1}"
      Environment = var.environment
      Module      = "rds"
      Role        = "reader"
    }
  )
}