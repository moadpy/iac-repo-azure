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

# Service Principals & Secrets (Manually queried & generated from Azure Active Directory)
github_actions_client_id     = "b9fea404-3dfd-4a80-b79e-a04c3376e43b"
github_actions_sp_object_id  = "539ec714-146e-4822-bc1e-f6b121231734"
github_actions_client_secret = ""

backend_client_id            = "9f782595-01f1-4ea0-acd0-cb6048fe452a"
backend_sp_object_id         = "870a1e89-7fe3-4298-9770-ade164ad7cd0"
backend_client_secret        = ""

