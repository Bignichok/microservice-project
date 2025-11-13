variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of ArgoCD Helm chart"
  type        = string
  default     = "5.51.6"
}

variable "admin_password" {
  description = "Admin password for ArgoCD (bcrypt hashed)"
  type        = string
  sensitive   = true
  # Default password: admin123! (bcrypt hash)
  default     = "$2a$12$hBwbOHm5r.DwjUn/J7lzMe.o7oQzitqLlYOj/wPLgk7vGtQ4J2oCG"
}

variable "ingress_enabled" {
  description = "Enable ingress for ArgoCD"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Host for ArgoCD ingress"
  type        = string
  default     = "argocd.local"
}

variable "repositories" {
  description = "List of Git repositories to configure in ArgoCD"
  type = list(object({
    name = string
    url  = string
    type = string
  }))
  default = []
}

variable "applications" {
  description = "List of ArgoCD applications to create"
  type = list(object({
    name        = string
    namespace   = string
    source_repo = string
    source_path = string
    dest_server = string
    dest_namespace = string
  }))
  default = []
}

variable "tags" {
  description = "Common tags to be applied to resources"
  type        = map(string)
  default     = {}
}