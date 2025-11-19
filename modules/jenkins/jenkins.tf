resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins.arn
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

resource "aws_iam_role" "jenkins" {
  name = "${var.cluster_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:jenkins"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Get EKS cluster info
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_iam_role_policy" "jenkins_ecr" {
  name = "${var.cluster_name}-jenkins-ecr-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.jenkins_chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  timeout    = 600
  wait       = true
  wait_for_jobs = true
  
  values = [templatefile("${path.module}/values.yaml", {
    namespace            = var.namespace
    service_account_name = kubernetes_service_account.jenkins.metadata[0].name
    admin_password       = var.jenkins_admin_password
    storage_class        = var.storage_class
    storage_size         = var.storage_size
    ecr_repository_url   = var.ecr_repository_url
    aws_region          = var.aws_region
  })]

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_service_account.jenkins,
    aws_iam_role_policy.jenkins_ecr
  ]
}