variable "ecr_name" {
  description = "Name of the ECR repository"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*$", var.ecr_name))
    error_message = "Name of the ECR repository can only contain lowercase letters, numbers, dots, underscores, and hyphens."
  }
}

variable "scan_on_push" {
  description = "Whether to enable automatic scanning of images on upload"
  type        = bool
  default     = true
}
