environment              = "preprod"
location                 = "westeurope"
resource_group_name      = "preprod-env-rg"
storage_container_name   = "ml-data-preprod"
ml_workspace_name        = "aml-rca-preprod"
deploy_frontdoor         = false
deploy_dev_vm            = true
deploy_developer_bastion = true
github_webhook_secret    = "f12171e7b365ed961cf119ee92ae643219271416"
github_token             = ""

# VNet settings for preprod (non-overlapping)
aks_vnet_cidr         = "10.100.0.0/16"
aks_subnet_cidr       = "10.100.0.0/22"
aks_agc_subnet_cidr   = "10.100.4.0/24"
dev_subnet_cidr       = "10.100.5.0/24"
pe_subnet_cidr        = "10.100.6.0/24"
functions_subnet_cidr = "10.100.7.0/24"

# Service SKUs
search_sku = "basic"

# Architectural Hub reference variables (disabled/empty by default)
hub_vnet_name                = ""
hub_vnet_resource_group_name = ""
