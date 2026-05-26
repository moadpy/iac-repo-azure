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

variable "database_name" {
  description = "Name of the Cosmos DB SQL database"
  type        = string
  default     = "rca_engine_db"
}

variable "container_name" {
  description = "Name of the Cosmos DB SQL container"
  type        = string
  default     = "incidents"
}

variable "partition_key_path" {
  description = "Partition key path for the container"
  type        = string
  default     = "/incident_id"
}

variable "public_network_access" {
  description = "Whether public network access is enabled"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
