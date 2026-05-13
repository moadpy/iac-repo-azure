# ===========================================================================
# Module: aks
# Purpose: Azure Kubernetes Service cluster for the RCA Engine backend
#
# Creates:
#   - AKS cluster with system node pool
#   - Optional user node pool (ML workloads)
#   - System-assigned Managed Identity
#   - Container Insights integration (Log Analytics)
#   - RBAC role assignment → ACR (AcrPull)
#
# Naming convention: aks-<suffix>
# ===========================================================================

# ---------------------------------------------------------------------------
# AKS Cluster
# ---------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.suffix}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # --- System node pool ---
  # When autoscaling is enabled Azure controls the actual node count
  # between min_count and max_count — node_count must NOT be set.
  # When autoscaling is disabled node_count is the fixed, static count.
  default_node_pool {
    name                        = "system"
    vm_size                     = var.system_node_vm_size
    os_disk_size_gb             = 50
    vnet_subnet_id              = var.subnet_id
    type                        = "VirtualMachineScaleSets"
    temporary_name_for_rotation = "tempsystem"

    # Autoscaler — mutually exclusive with node_count
    enable_auto_scaling = var.system_enable_auto_scaling
    min_count           = var.system_enable_auto_scaling ? var.system_min_count : null
    max_count           = var.system_enable_auto_scaling ? var.system_max_count : null
    # Fixed count — only used when autoscaling is OFF
    node_count          = var.system_enable_auto_scaling ? null : var.system_node_count

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # --- Identity ---
  identity {
    type = "SystemAssigned"
  }

  # --- Network ---
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # --- Azure AD RBAC ---
  azure_active_directory_role_based_access_control {
    managed            = true # required in azurerm ~3.x; deprecated but harmless
    azure_rbac_enabled = true
  }

  # --- Monitoring ---
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# User node pool for Backend Agent (FastAPI)
# ---------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = var.deploy_user_node_pool ? 1 : 0

  name                  = "backend"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  vnet_subnet_id        = var.subnet_id
  mode                  = "User"
  os_disk_size_gb       = 64 # Reduced from 128 as it's not ML-heavy

  # Autoscaler — same pattern as the system pool
  enable_auto_scaling = var.user_enable_auto_scaling
  min_count           = var.user_enable_auto_scaling ? var.user_min_count : null
  max_count           = var.user_enable_auto_scaling ? var.user_max_count : null
  node_count          = var.user_enable_auto_scaling ? null : var.user_node_count

  node_labels = {
    "app" = "rca-agent"
  }

  # No taints needed for general backend workloads

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# RBAC: AKS kubelet identity → ACR (AcrPull)
# Allows the cluster to pull images from the private container registry
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# ---------------------------------------------------------------------------
# RBAC: AKS cluster identity → VNet subnet (Network Contributor)
# Required for Azure CNI to manage NICs in the subnet
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_vnet" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
