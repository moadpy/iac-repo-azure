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

variable "search_sku" {
  description = "SKU for the AI Search service"
  type        = string
  default     = "standard"
}

variable "aks_principal_id" {
  description = "Principal ID of the AKS system-assigned identity (for Search RBAC)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
