output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "aks_kubelet_identity_object_id" {
  description = "Object ID of the auto-created AKS kubelet identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "aks_identity_principal_id" {
  description = "Principal ID of the AKS system-assigned identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
