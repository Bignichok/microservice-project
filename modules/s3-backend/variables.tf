variable "bucket_name" {
  description = "Name of the S3 bucket for storing Terraform state files"
  type        = string
  
  validation {
    condition     = length(var.bucket_name) > 3 && length(var.bucket_name) < 64
    error_message = "Bucket name must be between 3 and 63 characters."
  }
}

variable "table_name" {
  description = "Name of the DynamoDB table for locking Terraform state"
  type        = string
  default     = "terraform-locks"
}
