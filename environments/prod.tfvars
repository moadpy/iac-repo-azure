env      = "prod"
location = "westeurope"

# Sandbox: set this to the resource group name shown in your Pluralsight portal
resource_group_name = "your-sandbox-resource-group"

vnet_cidr             = "10.1.0.0/16"
public_subnet_cidrs   = ["10.1.100.0/24", "10.1.101.0/24"]
private_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24"]
database_subnet_cidrs = ["10.1.200.0/24", "10.1.201.0/24"]

# Standard_DS2_v2 = 2 CPUs. Max 3 nodes × 2 CPUs = 6 CPUs.
# (Sandbox: max 10 CPUs total, max 3 nodes per AKS cluster)
aks_node_vm_size   = "Standard_DS2_v2"
aks_node_count_min = 2
aks_node_count_max = 3

# Sandbox: only Free or Basic allowed for AI Search
search_sku = "basic"

# Sandbox: ML allowed SKUs include DS2_v2; max one instance
ml_compute_vm_size   = "Standard_DS2_v2"
ml_compute_max_nodes = 2

openai_gpt_model              = "gpt-4o"
openai_embedding_model        = "text-embedding-3-small"
openai_gpt_capacity_tpu       = 30
openai_embedding_capacity_tpu = 60
