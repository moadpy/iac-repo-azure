variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "workspace_name" {
  description = "Azure ML workspace name"
  type        = string
  default     = "aml-rca-dev"
}

variable "application_insights_id" {
  description = "ID of the Application Insights instance"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the Storage Account"
  type        = string
}

variable "container_registry_id" {
  description = "ID of the Container Registry"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
