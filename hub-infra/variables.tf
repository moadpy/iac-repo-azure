variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Hub Resource Group Name"
  type        = string
  default     = "hub-env-rg"
}

variable "vnet_cidr" {
  description = "Hub VNet CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bastion_subnet_cidr" {
  description = "CIDR range for AzureBastionSubnet (min /26 for Basic SKU)"
  type        = string
  default     = "10.0.1.0/26"
}

variable "jumpbox_subnet_cidr" {
  description = "CIDR range for Jumpbox subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "admin_username" {
  description = "Admin username for the Jumpbox VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file for the Jumpbox VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
