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

variable "cosmos_db_primary_key" {
  description = "Primary key of the Cosmos DB account"
  type        = string
  sensitive   = true
}

variable "ml_storage_primary_key" {
  description = "Primary access key of the ML data storage account"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
