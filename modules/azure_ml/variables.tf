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

variable "key_vault_id" {
  description = "Resource ID of the Key Vault"
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the ML data storage account"
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Container Registry"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace"
  type        = string
}

variable "private_subnet_id" {
  description = "Subnet ID for the compute cluster"
  type        = string
}

variable "ml_compute_vm_size" {
  description = "VM size for the training compute cluster"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "ml_compute_max_nodes" {
  description = "Maximum nodes for the training compute cluster"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
