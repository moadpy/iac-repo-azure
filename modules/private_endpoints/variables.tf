variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "env" {
  description = "Deployment environment (preprod or prod)"
  type        = string
}

variable "vnet_id" {
  description = "Resource ID of the Virtual Network"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of database subnet IDs where private endpoints are placed"
  type        = list(string)
}

variable "storage_account_id" {
  description = "Resource ID of the ML data Storage Account"
  type        = string
}

variable "cosmos_db_id" {
  description = "Resource ID of the Cosmos DB account"
  type        = string
}

variable "ai_search_id" {
  description = "Resource ID of the Azure AI Search service"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault"
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  type        = string
}

variable "azureml_id" {
  description = "Resource ID of the Azure ML workspace"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
