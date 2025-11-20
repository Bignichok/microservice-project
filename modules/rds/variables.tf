# Universal RDS Module Variables

# Core Configuration
variable "use_aurora" {
  description = "Whether to use Aurora Cluster (true) or regular RDS instance (false). Note: Aurora not available on AWS Free Tier"
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group. If empty, will use private subnets from VPC"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

# Database Engine Configuration
variable "engine" {
  description = "Database engine (postgres, mysql, aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "18.1"
}

variable "instance_class" {
  description = "RDS instance class (db.t3.micro for free tier)"
  type        = string
  default     = "db.t3.micro"
}

variable "parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = "postgres18"
}

# Aurora-specific Configuration
variable "reader_count" {
  description = "Number of Aurora reader instances (only for Aurora)"
  type        = number
  default     = 0
}

variable "reader_instance_class" {
  description = "Instance class for Aurora readers (if different from writer)"
  type        = string
  default     = ""
}

# RDS-specific Configuration
variable "allocated_storage" {
  description = "Initial allocated storage in GB (only for regular RDS)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB for autoscaling (only for regular RDS)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1) (only for regular RDS)"
  type        = string
  default     = "gp2"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment (only for regular RDS)"
  type        = bool
  default     = false
}

# Database Configuration
variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "app_db"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Backup retention period in days (0 for free tier, 1-7 for free tier with backups, up to 35 for paid)"
  type        = number
  default     = 0
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# Security Configuration
variable "storage_encrypted" {
  description = "Enable storage encryption (note: not free on db.t3.micro)"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if not specified, uses default)"
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Enable deletion protection (recommended for production)"
  type        = bool
  default     = false  # Changed from true to false for easier development/testing
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make the RDS instance publicly accessible"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "ARN for the monitoring role"
  type        = string
  default     = ""
}

# Parameter Groups
variable "cluster_parameters" {
  description = "List of cluster parameters for Aurora (dynamic parameters only)"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]
}

variable "db_parameters" {
  description = "List of database parameters for regular RDS (dynamic parameters only)"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}