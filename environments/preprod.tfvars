env      = "preprod"
location = "westeurope"

# Sandbox: set this to the resource group name shown in your Pluralsight portal
resource_group_name = "your-sandbox-resource-group"

vnet_cidr             = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.100.0/24", "10.0.101.0/24"]
private_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
database_subnet_cidrs = ["10.0.200.0/24", "10.0.201.0/24"]

aks_node_vm_size   = "Standard_DS2_v2"
aks_node_count_min = 1
aks_node_count_max = 2

# Sandbox: only Free or Basic allowed for AI Search
search_sku = "basic"

ml_compute_vm_size   = "Standard_DS2_v2"
ml_compute_max_nodes = 2

openai_gpt_model              = "gpt-4o"
openai_embedding_model        = "text-embedding-3-small"
openai_gpt_capacity_tpu       = 10
openai_embedding_capacity_tpu = 20
