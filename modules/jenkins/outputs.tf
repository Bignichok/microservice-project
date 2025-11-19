output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}"
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_account" {
  description = "Jenkins service account name"
  value       = kubernetes_service_account.jenkins.metadata[0].name
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
  depends_on = [helm_release.jenkins]
}