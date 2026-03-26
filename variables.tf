variable "resource_group_name" {
  description = "Name of the pre-existing resource group (sandbox: SP cannot create RGs)"
  type        = string
}

variable "env" {
  description = "Deployment environment name (preprod or prod)"
  type        = string
  validation {
    condition     = contains(["preprod", "prod"], var.env)
    error_message = "env must be one of: preprod, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ, minimum 2)"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnet CIDRs required (one per AZ)."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ, minimum 2)"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnet CIDRs required (one per AZ)."
  }
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets (one per AZ, minimum 2)"
  type        = list(string)
  validation {
    condition     = length(var.database_subnet_cidrs) >= 2
    error_message = "At least 2 database subnet CIDRs required (one per AZ)."
  }
}

variable "aks_node_vm_size" {
  description = "VM size for AKS default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "aks_node_count_min" {
  description = "Minimum node count for AKS autoscaler"
  type        = number
  default     = 1
  validation {
    condition     = var.aks_node_count_min >= 1
    error_message = "Minimum AKS node count must be at least 1."
  }
}

variable "aks_node_count_max" {
  description = "Maximum node count for AKS autoscaler"
  type        = number
  default     = 4
  validation {
    condition     = var.aks_node_count_max >= 1
    error_message = "Maximum AKS node count must be at least 1."
  }
}

variable "search_sku" {
  description = "SKU for Azure AI Search service (sandbox: only free or basic allowed)"
  type        = string
  default     = "basic"
  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.search_sku)
    error_message = "Invalid search_sku value."
  }
}

variable "ml_compute_vm_size" {
  description = "VM size for Azure ML compute cluster"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "ml_compute_max_nodes" {
  description = "Maximum node count for Azure ML compute cluster"
  type        = number
  default     = 2
  validation {
    condition     = var.ml_compute_max_nodes >= 1
    error_message = "ml_compute_max_nodes must be at least 1."
  }
}

variable "openai_gpt_model" {
  description = "Azure OpenAI GPT model name to deploy"
  type        = string
  default     = "gpt-4o"
}

variable "openai_embedding_model" {
  description = "Azure OpenAI embedding model name to deploy"
  type        = string
  default     = "text-embedding-3-small"
}

variable "openai_gpt_capacity_tpu" {
  description = "Throughput capacity (TPU) for GPT deployment"
  type        = number
  default     = 10
}

variable "openai_embedding_capacity_tpu" {
  description = "Throughput capacity (TPU) for embedding deployment"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
