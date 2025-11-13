variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_chart_version" {
  description = "Version of Jenkins Helm chart"
  type        = string
  default     = "4.8.3"
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
  type        = string
  sensitive   = true
  default     = "admin123!"
}

variable "storage_class" {
  description = "Storage class for Jenkins PVC"
  type        = string
  default     = "gp2"
}

variable "storage_size" {
  description = "Storage size for Jenkins PVC"
  type        = string
  default     = "10Gi"
}

variable "ecr_repository_url" {
  description = "ECR repository URL for image builds"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags to be applied to resources"
  type        = map(string)
  default     = {}
}