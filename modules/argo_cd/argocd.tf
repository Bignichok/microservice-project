resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Install ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  timeout    = 600

  values = [templatefile("${path.module}/values.yaml", {
    namespace         = var.namespace
    admin_password    = var.admin_password
    ingress_enabled   = var.ingress_enabled
    ingress_host      = var.ingress_host
  })]

  depends_on = [kubernetes_namespace.argocd]
}

# Create ArgoCD applications using custom Helm chart
resource "helm_release" "argocd_apps" {
  count = length(var.applications) > 0 ? 1 : 0
  
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [templatefile("${path.module}/charts/values.yaml", {
    repositories  = var.repositories
    applications  = var.applications
  })]

  depends_on = [helm_release.argocd]
}