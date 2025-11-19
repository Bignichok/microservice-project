# CI/CD Components Terraform Configuration
# This file should be deployed after the main infrastructure (main.tf)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-bucket-microservice-project-bignichok"
    key            = "cicd/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for EKS cluster info
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

module "jenkins" {
  source = "../modules/jenkins"
  
  cluster_name          = var.cluster_name
  namespace            = "jenkins"
  jenkins_admin_password = "admin123!"
  ecr_repository_url   = var.ecr_repository_url
  aws_region           = var.aws_region
  
  tags = {
    Environment = "microservice-project"
    Project     = "microservice-project"
    ManagedBy   = "terraform"
  }
}

module "argo_cd" {
  source = "../modules/argo_cd"
  
  cluster_name = var.cluster_name
  namespace    = "argocd"
  
  repositories = [
    {
      name = "microservice-charts"
      url  = "https://github.com/Bignichok/microservice-project.git"
      type = "git"
    }
  ]
  
  applications = [
    {
      name           = "django-app"
      namespace      = "argocd"
      source_repo    = "https://github.com/Bignichok/microservice-project.git"
      source_path    = "charts/django-app"
      dest_server    = "https://kubernetes.default.svc"
      dest_namespace = "default"
    }
  ]
  
  tags = {
    Environment = "microservice-project"
    Project     = "microservice-project"
    ManagedBy   = "terraform"
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

output "jenkins_info" {
  description = "Information about Jenkins installation"
  value = {
    jenkins_url             = module.jenkins.jenkins_url
    jenkins_namespace       = module.jenkins.jenkins_namespace
    jenkins_service_account = module.jenkins.jenkins_service_account
  }
  sensitive = false
}

output "argocd_info" {
  description = "Information about ArgoCD installation"
  value = {
    argocd_url                 = module.argo_cd.argocd_url
    argocd_namespace           = module.argo_cd.argocd_namespace
    argocd_server_service_name = module.argo_cd.argocd_server_service_name
  }
  sensitive = false
}