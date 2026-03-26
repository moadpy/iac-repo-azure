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

variable "openai_gpt_model" {
  description = "GPT model name to deploy (e.g. gpt-4o)"
  type        = string
}

variable "openai_embedding_model" {
  description = "Embedding model name to deploy (e.g. text-embedding-3-small)"
  type        = string
}

variable "openai_gpt_capacity_tpu" {
  description = "Throughput units for the GPT deployment"
  type        = number
}

variable "openai_embedding_capacity_tpu" {
  description = "Throughput units for the embedding deployment"
  type        = number
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
