variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "env" {
  description = "Environment name (preprod or prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (AKS nodes placed in first subnet)"
  type        = list(string)
}

variable "acr_id" {
  description = "Resource ID of the Container Registry (for AcrPull role)"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for OMS agent"
  type        = string
}

variable "vnet_id" {
  description = "Resource ID of the VNet (for Network Contributor role assignment)"
  type        = string
}

variable "node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "node_count_min" {
  description = "Minimum node count for autoscaler"
  type        = number
  default     = 1
}

variable "node_count_max" {
  description = "Maximum node count for autoscaler"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
