# ─────────────────────────────────────────────────────────────────────────────
# AKS Cluster
# Sandbox constraints:
#   - Max 3 nodes per cluster
#   - Standalone managed identities not supported — AKS auto-creates its kubelet
#     identity; reference via .kubelet_identity[0].object_id
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-predictive-maintenance-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.env}"
  tags                = var.tags

  default_node_pool {
    name                = "system"
    vm_size             = var.node_vm_size
    node_count          = var.node_count_min
    zones               = ["1", "2"]
    enable_auto_scaling = true
    min_count           = var.node_count_min
    max_count           = var.node_count_max
    vnet_subnet_id      = var.private_subnet_ids[0]
    os_disk_size_gb     = 50

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    outbound_type     = "userAssignedNATGateway"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }
}

# Sandbox: roleAssignments/write is blocked — assign AcrPull and Network Contributor manually in the portal.
