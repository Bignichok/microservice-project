output "argocd_url" {
  description = "ArgoCD URL"
  value = var.ingress_enabled ? "https://${var.ingress_host}" : "http://${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname}"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = "admin123!"
  sensitive   = true
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = "argocd-server"
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}