# ===========================================================================
# Module: aks — Input Variables
# ===========================================================================

# ---------------------------------------------------------------------------
# Required
# ---------------------------------------------------------------------------
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Container Insights"
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry (for AcrPull role assignment)"
  type        = string
}

variable "vnet_id" {
  description = "Resource ID of the VNet (for Network Contributor role assignment)"
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the subnet where AKS nodes will be deployed"
  type        = string
}

# ---------------------------------------------------------------------------
# AKS — Cluster settings
# ---------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version to deploy"
  type        = string
  default     = "1.35"
}

variable "sku_tier" {
  description = "AKS SKU tier: Free (no SLA) or Standard (99.95% SLA)"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be 'Free', 'Standard', or 'Premium'."
  }
}

# ---------------------------------------------------------------------------
# AKS — System node pool
# ---------------------------------------------------------------------------
variable "system_node_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_enable_auto_scaling" {
  description = "Enable Cluster Autoscaler for the system node pool (Azure manages the count between min/max)"
  type        = bool
  default     = true
}

variable "system_min_count" {
  description = "Minimum node count when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "system_max_count" {
  description = "Maximum node count when autoscaling is enabled"
  type        = number
  default     = 3
}

variable "system_node_count" {
  description = "Fixed node count when autoscaling is DISABLED (ignored when system_enable_auto_scaling = true)"
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# AKS — User (ML) node pool
# ---------------------------------------------------------------------------
variable "deploy_user_node_pool" {
  description = "Whether to deploy a dedicated user node pool for ML workloads"
  type        = bool
  default     = false
}

variable "user_node_vm_size" {
  description = "VM size for the user (ML workload) node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "user_enable_auto_scaling" {
  description = "Enable Cluster Autoscaler for the user node pool"
  type        = bool
  default     = true
}

variable "user_min_count" {
  description = "Minimum node count for the user pool when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "user_max_count" {
  description = "Maximum node count for the user pool when autoscaling is enabled"
  type        = number
  default     = 2
}

variable "user_node_count" {
  description = "Fixed node count for the user pool when autoscaling is DISABLED"
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# AKS — Networking
# ---------------------------------------------------------------------------
variable "service_cidr" {
  description = "CIDR range for Kubernetes services (must not overlap with VNet)"
  type        = string
  default     = "10.200.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for the Kubernetes DNS service (must be in service_cidr)"
  type        = string
  default     = "10.200.0.10"
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
