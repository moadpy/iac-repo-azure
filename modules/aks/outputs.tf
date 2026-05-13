# ===========================================================================
# Module: aks — Outputs
# ===========================================================================

output "aks_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster (sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Structured kubeconfig object"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "cluster_fqdn" {
  description = "Fully qualified domain name of the AKS API server"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL — used for Workload Identity federation"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet Managed Identity (for RBAC assignments)"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster's system-assigned Managed Identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "node_resource_group" {
  description = "Auto-generated resource group that holds AKS infrastructure nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}
