variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "openai_location" {
  description = "Azure region for Azure OpenAI (not all regions support it)"
  type        = string
  default     = "westeurope"
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}

variable "public_network_access" {
  description = "Whether public network access is enabled (true for dev, false for prod with PE)"
  type        = bool
  default     = true
}

# --- Chat model variables ---
variable "chat_model_name" {
  description = "Name of the chat model to deploy"
  type        = string
  default     = "gpt-4o-mini"
}

variable "chat_model_version" {
  description = "Version of the chat model"
  type        = string
  default     = "2024-07-18"
}

variable "chat_sku_name" {
  description = "SKU name for chat deployment (Standard, DataZoneStandard, etc.)"
  type        = string
  default     = "Standard"
}

variable "chat_sku_capacity" {
  description = "Capacity (TPU) for chat deployment"
  type        = number
  default     = 10
}

# --- Embedding model variables ---
variable "embedding_model_name" {
  description = "Name of the embedding model to deploy"
  type        = string
  default     = "text-embedding-3-small"
}

variable "embedding_model_version" {
  description = "Version of the embedding model"
  type        = string
  default     = "1"
}

variable "embedding_sku_name" {
  description = "SKU name for embedding deployment"
  type        = string
  default     = "Standard"
}

variable "embedding_sku_capacity" {
  description = "Capacity (TPU) for embedding deployment"
  type        = number
  default     = 120
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
