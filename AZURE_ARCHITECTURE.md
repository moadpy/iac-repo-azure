# Azure Architecture: MLOps + LLMOps — Industrial Predictive Maintenance Platform

> **Purpose**: Practice MLOps and LLMOps best practices on Azure by building an industrial predictive maintenance platform. A supervised ML model predicts machine failure types from sensor telemetry. When a failure is predicted, a RAG system powered by Azure OpenAI retrieves the relevant repair procedures and generates a step-by-step remediation guide for the maintenance engineer.
>
> **Target Platform**: Pluralsight Azure AI Sandboxes (4h sessions) — Infrastructure fully provisioned via Terraform with CI/CD automation.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Kaggle Dataset & ML Model](#2-kaggle-dataset--ml-model)
3. [AWS → Azure Service Mapping](#3-aws--azure-service-mapping)
4. [Network Architecture (Azure VNet)](#4-network-architecture-azure-vnet)
5. [Pipeline 1 — ML Training (MLOps)](#5-pipeline-1--ml-training-mlops)
6. [Pipeline 2 — RAG Ingestion (LLMOps)](#6-pipeline-2--rag-ingestion-llmops)
7. [Pipeline 3 — User Query Flow](#7-pipeline-3--user-query-flow)
8. [Repository & CI/CD Strategy](#8-repository--cicd-strategy)
9. [Terraform Module Structure](#9-terraform-module-structure)
10. [Environment Configuration](#10-environment-configuration)
11. [Sandbox Constraints & Bootstrap Strategy](#11-sandbox-constraints--bootstrap-strategy)

---

## 1. Project Overview

### Architecture Paradigm: Supervised ML + RAG (No Foundation Model Training)

The platform combines two AI paradigms serving a single coherent use case — industrial machine maintenance:

**MLOps layer**: A supervised classification model is trained on industrial machine telemetry (temperature, rotational speed, torque, tool wear) to predict the specific type of failure a machine is about to experience. The model is trained on Azure Machine Learning, versioned in the model registry, and deployed as a managed Online Endpoint. This demonstrates the full MLOps lifecycle: reproducible training pipelines, MLflow experiment tracking, model versioning, and automated Blue/Green deployment via CI/CD.

**LLMOps layer**: A RAG system retrieves the relevant maintenance procedure manual when a failure is predicted. Azure OpenAI provides both embeddings (text-embedding-3-small) and generation (GPT-4o). Procedure manuals are authored in Markdown, versioned in Git, and indexed into Azure AI Search through an automated ingestion pipeline. This demonstrates LLMOps practices: prompt versioning, embedding pipeline management, and grounded generation.

### Application: Industrial Predictive Maintenance Assistant

The application targets **maintenance engineers** in a manufacturing or industrial facility. The scenario is:

1. A maintenance engineer opens the web dashboard and selects a machine by its ID.
2. The dashboard displays the machine's latest sensor readings (fetched from a telemetry store in Azure Blob Storage, simulating a SCADA/IoT system).
3. The engineer submits the readings for analysis. The FastAPI backend sends them to the Azure ML Online Endpoint, which predicts the failure type and confidence score.
4. If a failure is predicted (or the engineer describes a symptom), the RAG pipeline retrieves the top matching maintenance procedure chunks from Azure AI Search.
5. Azure OpenAI (GPT-4o) assembles all context — predicted failure type, sensor readings, relevant procedure excerpts, conversation history — and generates a precise, actionable remediation guide.
6. The engineer follows the guide. The Q&A session is saved for audit and future context.

### What This Demonstrates

| Practice | Demonstrated by |
|---|---|
| **MLOps** | Azure ML training pipeline, MLflow tracking, model registry, Online Endpoint, automated CI/CD deploy |
| **LLMOps** | Markdown procedures versioned in Git, chunking/embedding pipeline, prompt versioning in Blob Storage, RAG with grounded generation |
| **DevOps / IaC** | Full Terraform modules, multi-environment (preprod/prod), GitHub Actions CI/CD, GitOps with ArgoCD |
| **Security** | VNet 3-tier isolation, Private Endpoints for all PaaS services, NSGs, Azure Key Vault, Managed Identity |
| **HA** | 2 Availability Zones per environment, AKS multi-AZ node pools, Cosmos DB zone-redundant |

---

## 2. Kaggle Dataset & ML Model

### Dataset

**Name**: Machine Predictive Maintenance Classification
**Source**: `https://www.kaggle.com/datasets/shivamb/machine-predictive-maintenance-classification`
**Size**: 10,000 records — clean, no missing values, no data science preprocessing required

### Features

The dataset represents sensor telemetry from industrial machines:

| Feature | Description |
|---|---|
| `air_temperature_K` | Ambient air temperature around the machine (Kelvin) |
| `process_temperature_K` | Internal process temperature (Kelvin) |
| `rotational_speed_rpm` | Spindle/shaft rotation speed (RPM) |
| `torque_Nm` | Mechanical torque applied (Newton-metres) |
| `tool_wear_min` | Cumulative tool operating time (minutes) |
| `type` | Machine grade: L (light), M (medium), H (heavy) |

**Target**: `failure_type` — 6-class classification:

| Class | Description | Maintenance Action |
|---|---|---|
| `No Failure` | Machine operating normally | Monitor only |
| `Heat Dissipation Failure` | Cooling system degradation, thermal runaway risk | Inspect cooling fans, clean heat exchangers |
| `Power Failure` | Electrical supply anomaly | Check power supply unit, fuses, electrical connections |
| `Overstrain Failure` | Mechanical load exceeds tolerance | Reduce load, inspect drive components, check belt/chain |
| `Tool Wear Failure` | Cutting/machining tool beyond service life | Replace tool, recalibrate toolpath |
| `Random Failures` | Stochastic fault — no clear root cause | Full diagnostic inspection required |

### Why No Data Science Work is Needed

The dataset is synthetic, balanced, and pre-labeled. The training script (`src/train.py`) is a standard XGBoost multi-class pipeline with MLflow logging — ~100 lines of code. The point of the project is **not** the model itself but the infrastructure and automation around it:
- Is training reproducible? (Azure ML pipeline)
- Are experiments tracked? (MLflow)
- Is the model versioned? (Azure ML Model Registry)
- Is deployment automated? (CI/CD → Online Endpoint)
- Is promotion gated on quality? (accuracy threshold check before registering)

### Maintenance Procedures (RAG Knowledge Base)

Engineers write the procedures in Markdown. One file per failure type. These live in `ml-repo/procedures/` and are synced to Azure Blob Storage, triggering the ingestion pipeline:

```
ml-repo/procedures/
├── heat_dissipation_failure.md    # Cooling inspection, fan replacement, thermal paste guide
├── power_failure.md               # PSU diagnosis, fuse check, electrical safety protocol
├── overstrain_failure.md          # Load reduction, mechanical inspection checklist
├── tool_wear_failure.md           # Tool change procedure, recalibration steps
├── random_failure.md              # Full diagnostic checklist, escalation path
└── preventive_maintenance.md      # General scheduled maintenance intervals
```

---

## 3. AWS → Azure Service Mapping

| Component | AWS (Previous) | Azure (New) | Notes |
|---|---|---|---|
| **Network isolation** | VPC | Azure Virtual Network (VNet) | Same concept |
| **Subnet tiers** | Public / Private / DB subnets | Public / Private / DB subnets in VNet | Same 3-tier design |
| **High Availability** | 2 Availability Zones | 2 Availability Zones | Identical model |
| **Outbound NAT** | NAT Gateway (per AZ) | Azure NAT Gateway (per AZ) | Identical behavior |
| **Private service access** | VPC Interface Endpoints | Azure Private Endpoints + Private DNS Zones | Per-service, DNS-transparent |
| **Firewall / ACL** | Security Groups + NACLs | Network Security Groups (NSG) | Subnet or NIC attached |
| **CDN + WAF** | CloudFront + WAF | Azure Front Door (Standard) | Built-in WAF, global anycast |
| **Frontend storage** | S3 (static website) | Azure Blob Storage (Static Website) | Identical concept |
| **API entry point** | API Gateway (HTTP) + VPC Link | Azure Application Gateway (WAF v2) | WAF + routing into private VNet |
| **Container orchestration** | EKS | Azure Kubernetes Service (AKS) | Azure CNI, Workload Identity, **Private Cluster** |
| **Container registry** | ECR | Azure Container Registry (ACR) | Premium SKU for Private Endpoint |
| **NoSQL / Session store** | DynamoDB | Azure Cosmos DB (NoSQL API) | Serverless mode for sandboxes |
| **Vector search** | OpenSearch (k-NN) | Azure AI Search (vector search) | HNSW algorithm + semantic ranking |
| **Serverless ingestion** | Lambda (VPC) | AKS CronJob (rag-ingest) | Runs inside cluster on weekly schedule — no external compute needed |
| **Secrets** | Secrets Manager | Azure Key Vault | Managed Identity access — no passwords |
| **ML Training** | SageMaker Training Jobs | Azure Machine Learning (Training Jobs) | **RESTORED** — core MLOps component |
| **ML Inference endpoint** | SageMaker Managed Endpoint | Azure ML Online Endpoint | Hosts trained failure classifier |
| **LLM / Generation** | Amazon Bedrock (Claude 3) | Azure OpenAI Service (GPT-4o) | Managed, no infra to provision |
| **Embeddings (RAG)** | Amazon Bedrock (Titan) | Azure OpenAI (text-embedding-3-small) | Same managed approach |
| **Monitoring / Logs** | CloudWatch | Azure Monitor + Log Analytics Workspace | Equivalent |
| **Machine telemetry source** | EC2 API + CloudWatch (VM metrics) | Azure Blob Storage (simulated SCADA telemetry) | CSV time-series per machine ID |
| **DNS** | Route 53 | Azure DNS | Same concept |
| **IaC State** | S3 + DynamoDB lock | Azure Blob Storage (azurerm backend) | Built-in state locking via Blob lease |
| **CI/CD Identity** | OIDC → IAM Role | Service Principal + GitHub Secrets | OIDC federation also available |
| **GitOps** | ArgoCD on EKS | ArgoCD on AKS | Unchanged |
| **Secure admin access** | Session Manager / Bastion | **Azure Bastion + Jumpbox VM** | Hub VNet peered to Spoke — browser-based SSH |
| **Management hub network** | Transit Gateway / Hub VPC | **Hub VNet (10.10.0.0/16)** | Deployed once, peered to all Spoke VNets |

---

## 4. Network Architecture (Azure VNet)

### Design Principles

- **3-Tier subnet model** preserved: Public (gateway tier), Private (application tier), Database (data tier).
- **2 Availability Zones** per environment for high availability.
- Zero direct internet access from Private and Database tiers — outbound via NAT Gateway, inbound via Application Gateway only.
- **Private Endpoints** for all PaaS services — all traffic stays within the VNet.
- **NSGs** on each subnet tier enforce traffic segmentation.

### Address Space

| VNet | CIDR | Purpose |
|---|---|---|
| Hub | `10.10.0.0/16` | Management plane — Bastion + Jumpbox (deployed once) |
| preprod (Spoke) | `10.0.0.0/16` | Application workloads — Preprod environment |
| prod (Spoke) | `10.1.0.0/16` | Application workloads — Prod environment |

### Subnet Layout (Spoke VNet — per environment)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Spoke VNet  10.x.0.0/16                                                │
│                                                                          │
│  PUBLIC TIER — Application Gateway + NAT Gateway                        │
│  ┌─────────────────────────────┬──────────────────────────────────┐    │
│  │  AZ1: 10.x.100.0/24         │  AZ2: 10.x.101.0/24             │    │
│  │  [App Gateway WAF v2]        │  [NAT Gateway EIP-2]             │    │
│  │  [NAT Gateway EIP-1]         │                                  │    │
│  └─────────────────────────────┴──────────────────────────────────┘    │
│                    ▼ (path-based routing to AKS Internal LB)             │
│  PRIVATE TIER — AKS (Private Cluster)                                   │
│  ┌─────────────────────────────┬──────────────────────────────────┐    │
│  │  AZ1: 10.x.0.0/24           │  AZ2: 10.x.1.0/24               │    │
│  │  [AKS Node Pool]             │  [AKS Node Pool]                 │    │
│  │  [Private API Server PE]     │                                  │    │
│  └─────────────────────────────┴──────────────────────────────────┘    │
│                    ▼ (all via Private Endpoints)                         │
│  DATABASE TIER — Private Endpoints for all PaaS                         │
│  ┌─────────────────────────────┬──────────────────────────────────┐    │
│  │  AZ1: 10.x.200.0/24         │  AZ2: 10.x.201.0/24             │    │
│  │  [PE: Cosmos DB]             │  [PE: Azure AI Search]           │    │
│  │  [PE: Blob Storage]          │  [PE: ACR]                       │    │
│  │  [PE: Key Vault]             │  [PE: Azure ML]                  │    │
│  └─────────────────────────────┴──────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
          │ VNet Peering (bidirectional)
          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Hub VNet  10.10.0.0/16  (deployed once via hub/ Terraform root)        │
│                                                                          │
│  BASTION TIER — AzureBastionSubnet (Azure-enforced name)                │
│  ┌───────────────────────────────────────────────────────────────┐      │
│  │  10.10.0.0/26                                                  │      │
│  │  [Azure Bastion Host — Public IP for browser SSH]              │      │
│  └───────────────────────────────────────────────────────────────┘      │
│                                                                          │
│  MANAGEMENT TIER — Jumpbox VM                                            │
│  ┌───────────────────────────────────────────────────────────────┐      │
│  │  10.10.1.0/24                                                  │      │
│  │  [Jumpbox VM — Standard_B1s — kubectl, helm, az cli]          │      │
│  │  [NSG: SSH from Bastion only — no public IP]                   │      │
│  └───────────────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Private Endpoints & DNS Zones

| Service | Private DNS Zone |
|---|---|
| Azure Blob Storage | `privatelink.blob.core.windows.net` |
| Azure Cosmos DB | `privatelink.documents.azure.com` |
| Azure AI Search | `privatelink.search.windows.net` |
| Azure Key Vault | `privatelink.vaultcore.azure.net` |
| Azure Container Registry | `privatelink.azurecr.io` |
| Azure ML Workspace | `privatelink.api.azureml.ms` |
| **AKS API Server** | **`privatelink.<region>.azmk8s.io`** (auto-created by Azure when `private_cluster_enabled = true`) |

All Private DNS Zones are linked to the Spoke VNet. The **AKS Private DNS Zone is additionally linked to the Hub VNet** so the Jumpbox can resolve the private API Server hostname.

### NSG Rules Summary

| Tier | Inbound | Outbound |
|---|---|---|
| Public | Internet → 443 (App Gateway health probes + users) | All (Azure management) |
| Private | App Gateway → 8080 (FastAPI pods); VNet CIDR → all | VNet CIDR (Private Endpoints); internet via NAT (for image pulls) |
| Database | VNet CIDR → 443 only | Deny all |
| **Management** | **SSH (22) from AzureBastionSubnet CIDR only; Deny all other inbound** | **VNet CIDR (to reach AKS API via peering); Internet (for az cli, apt)** |

---

## 5. Pipeline 1 — ML Training (MLOps)

The full MLOps lifecycle for the predictive maintenance classifier.

```
Step 1: Feature branch push
   Engineer creates feature/train-v2 branch
   Commits: src/train.py, src/preprocess.py, pipelines/training_pipeline.py
   Opens Pull Request → develop

Step 2: CI Validation  [ml_ci.yml — triggers on PR]
   ├── Checkout + setup Python 3.11
   ├── pip install -r requirements.txt
   ├── flake8 linting
   ├── pytest: unit tests on preprocess.py
   └── Validate Azure ML pipeline YAML schema

Step 3: Merge to develop  [ml_train.yml — targets preprod]
   ├── az login (Service Principal)
   ├── Upload dataset CSV to Azure Blob Storage (ml-data/datasets/)
   │     └── Register as Azure ML Data Asset (versioned, immutable snapshot)
   ├── Submit Azure ML Training Job
   │     Compute: Standard_DS2_v2 cluster (auto-scale 0→2, scales to 0 when idle)
   │     Environment: Azure ML curated Python 3.11 + XGBoost + MLflow
   │     Script: src/train.py
   │       ├── Load Data Asset (pandas, feature engineering)
   │       ├── Encode: failure_type → integer label, type → one-hot
   │       ├── Train: XGBoostClassifier (n_estimators, max_depth, learning_rate)
   │       ├── Evaluate: accuracy, F1-macro, per-class precision/recall
   │       ├── MLflow autolog: params, metrics, confusion matrix PNG
   │       └── Save: model.pkl to outputs/
   ├── Await job completion
   ├── Gate: if F1-macro >= 0.85:
   │     ├── Register model in Azure ML Model Registry
   │     │     (name: predictive-maintenance-classifier, version: auto-incremented)
   │     └── Deploy to Azure ML Online Endpoint (preprod)
   │           Blue/Green: new deployment → shift 100% traffic → retire old
   └── Store endpoint URI in Azure Key Vault (preprod/ml/endpoint-url)

Step 4: Merge develop → main  [ml_train.yml — targets prod]
   └── Same flow, prod Azure ML Workspace → prod Online Endpoint
```

### MLflow Tracking (Native to Azure ML)

Every job automatically logs:
- **Parameters**: `n_estimators`, `max_depth`, `learning_rate`, `scale_pos_weight`
- **Metrics**: `accuracy`, `f1_macro`, `roc_auc_ovr`, per-class F1
- **Artifacts**: `model.pkl`, `confusion_matrix.png`, `feature_importances.png`
- **Data lineage**: which Data Asset version was used for this run

Azure ML Studio provides a visual comparison dashboard across all runs — no extra setup.

### Compute (cost-efficient for sandboxes)

The training compute cluster scales to **0 nodes when idle** (after 2 minutes), so it costs nothing between training runs. A job wakes it up in ~3 minutes and scales back to 0 when done.

---

## 6. Pipeline 2 — RAG Ingestion (LLMOps)

Maintenance procedure manuals written in Markdown are automatically chunked, embedded, and indexed into Azure AI Search.

```
Step 1: Engineer writes/updates a procedure file
   feature/update-overstrain-procedure → PR → develop

Step 2: Merge to develop  [blob_sync.yml]
   ├── az login
   ├── Branch determines target:
   │     develop → preprod Storage Account
   │     main    → prod    Storage Account
   ├── az storage blob sync  prompts/    → ml-data container/prompts/
   └── az storage blob sync  procedures/ → ml-data container/procedures/
         └── New/updated blobs emit Azure Event Grid events

Step 3: CI/CD Pipeline Job or AKS CronJob
   ├── *Architecture Note: Pluralsight sandboxes block serverless Azure Functions creation (0 quota). The Event Grid trigger was replaced by a CI/CD job.*
   ├── Read new .md blob from Blob Storage
   └── For each file:
         ├── Parse Markdown → extract plain text
         ├── Chunk: 512-token segments, 50-token overlap (LangChain RecursiveCharacterTextSplitter)
         └── For each chunk:
               ├── Call Azure OpenAI (text-embedding-3-small) → float[1536] vector
               └── Index document into Azure AI Search:
                     {
                       id:           "uuid",
                       content:      "chunk text",
                       embedding:    [1536 floats],
                       source_file:  "procedures/overstrain_failure.md",
                       failure_type: "Overstrain Failure",
                       chunk_index:  3
                     }

Step 4: Azure AI Search index updated
   └── Chunks available for k-NN / hybrid semantic search,
         filterable by failure_type field
```

### LLMOps — Prompt Versioning

The system prompt for GPT-4o is stored in `ml-repo/prompts/system_prompt.txt`, synced to Azure Blob Storage with versioning enabled. FastAPI reads it at startup and can hot-reload it without redeploying the application — prompt changes are a pure content operation, not a code deployment. This is a core LLMOps practice separating prompt lifecycle from application lifecycle.

---

## 7. Pipeline 3 — User Query Flow

Full end-to-end request: from maintenance engineer browser to AI-generated repair guide.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                      USER QUERY FLOW                                          │
│                                                                                │
│  Maintenance Engineer — Browser                                                │
│      │  HTTPS POST /api/analyze  { machine_id, question }                     │
│      ▼                                                                         │
│  Azure Front Door (CDN + WAF)                                                  │
│      │  Global anycast → WAF rule inspection                                   │
│      ▼                                                                         │
│  Azure Application Gateway (WAF v2) — public subnet                            │
│      │  /api/* → AKS Internal Load Balancer (private subnet)                  │
│      ▼                                                                         │
│  FastAPI Pod (AKS)  ── Workload Identity → all downstream calls               │
│      │                                                                         │
│      ├── Step 1: Extract machine_id + session_id from request                 │
│      │                                                                         │
│      ├── Step 2: Fetch conversation history                                     │
│      │      └── Cosmos DB (NoSQL) via Private Endpoint                         │
│      │            GET sessions/{session_id}/messages                            │
│      │                                                                         │
│      ├── Step 3: Fetch latest machine telemetry                                │
│      │      └── Azure Blob Storage (ml-data/telemetry/{machine_id}/latest.csv)│
│      │            Simulates SCADA/IoT reading:                                  │
│      │            { air_temp, process_temp, rpm, torque, tool_wear, type }     │
│      │            (In production: replace with Azure IoT Hub / Event Hub)      │
│      │                                                                         │
│      ├── Step 4: ML Inference — Failure Prediction                             │
│      │      └── Azure ML Online Endpoint (via Private Endpoint)                │
│      │            Input:  { air_temp, process_temp, rpm, torque,               │
│      │                       tool_wear, type_encoded }                          │
│      │            Output: { predicted_failure_type, confidence_score,          │
│      │                       class_probabilities[6] }                           │
│      │                                                                         │
│      ├── Step 5: Query Augmentation + Embedding                                │
│      │      ├── Concatenate: question + sensor readings + predicted_failure    │
│      │      └── Azure OpenAI (text-embedding-3-small) via Public Internet (NAT Gateway)│
│      │            Output: float[1536] query vector                             │
│      │                                                                         │
│      ├── Step 6: RAG — Procedure Retrieval                                     │
│      │      └── Azure AI Search (via Private Endpoint)                         │
│      │            k-NN search filtered by predicted_failure_type               │
│      │            → top 5 procedure chunks most relevant to this fault         │
│      │                                                                         │
│      ├── Step 7: Prompt Assembly + Generation                                  │
│      │      ├── Fetch system_prompt.txt from Blob Storage (versioned)          │
│      │      ├── Build final prompt:                                             │
│      │      │     [system prompt — maintenance expert persona]                  │
│      │      │     [conversation history — Cosmos DB]                            │
│      │      │     [top-5 procedure excerpts — Azure AI Search]                 │
│      │      │     [machine telemetry: sensor readings]                          │
│      │      │     [ML prediction: failure type + confidence + probabilities]    │
│      │      │     [engineer question]                                           │
│      │      └── Azure OpenAI (GPT-4o) via Public Internet (NAT Gateway)        │
│      │            → generates step-by-step repair guide                         │
│      │                                                                         │
│      └── Step 8: Persist + Return                                              │
│             ├── Cosmos DB: PutItem — save { question, response, machine_id,    │
│             │     predicted_failure_type, sensor_snapshot, timestamp }          │
│             └── Return response to engineer via App Gateway → Front Door        │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Frontend

The React dashboard displays:
- Machine selector (ID + current status)
- Live sensor reading gauges (temperature, RPM, torque, tool wear)
- ML prediction badge: failure type + confidence percentage + probability bar chart
- Chat interface with the AI maintenance assistant
- Conversation history

The frontend is built and pushed to Azure Blob Storage (Static Website) by `cd.yml` on every merge. Azure Front Door serves it globally.

---

## 8. Repository & CI/CD Strategy

### Git Branching (unchanged from original strategy)

```
feature/*  ──PR──►  develop  ──PR──►  main
               (preprod CI/CD)     (prod CI/CD)
```

### Repositories

| Repo | Content | Pipelines |
|---|---|---|
| `iac-repo` | Terraform (this repo) | `terraform_ci.yml`, `terraform_apply.yml` |
| `ml-repo` | Training code + Markdown procedures + Prompts | `ml_ci.yml`, `ml_train.yml`, `blob_sync.yml` |
| `app-repo` | FastAPI backend + React frontend | `ci.yml`, `cd.yml` |
| `gitops-repo` | Kubernetes manifests | No pipelines — ArgoCD watches this repo |

### `ml-repo` Structure

```
ml-repo/
├── .github/workflows/
│   ├── ml_ci.yml           # lint + unit tests on feature/* PRs
│   ├── ml_train.yml        # submit Azure ML training job on merge
│   └── blob_sync.yml       # sync prompts/ + procedures/ to Blob Storage
├── src/
│   ├── train.py            # Azure ML training script (XGBoost + MLflow)
│   ├── preprocess.py       # feature engineering (encoding, normalization)
│   └── score.py            # scoring script for Online Endpoint
├── pipelines/
│   └── training_pipeline.py   # Azure ML Pipeline component definition
├── prompts/
│   └── system_prompt.txt   # GPT-4o persona + instructions (versioned in Blob)
└── procedures/
    ├── heat_dissipation_failure.md
    ├── power_failure.md
    ├── overstrain_failure.md
    ├── tool_wear_failure.md
    ├── random_failure.md
    └── preventive_maintenance.md
```

### iac-repo GitHub Actions

#### `terraform_ci.yml` — triggered on PR to `develop` or `main`
1. Checkout + Setup Terraform
2. `az login` with read-only Service Principal
3. Bootstrap check: verify Azure Blob Storage backend exists
4. `terraform init` (Azure backend)
5. `terraform validate` + `terraform fmt -check`
6. TFLint + Checkov security scan
7. `terraform plan -var-file=environments/{env}.tfvars`
8. Post plan output as PR comment

#### `terraform_apply.yml` — triggered on push to `develop` or `main`
1. Checkout + Setup Terraform
2. Bootstrap: idempotent creation of Azure Blob Storage state container
3. Determine environment: `develop` → preprod, `main` → prod
4. `az login` with contributor Service Principal
5. `terraform init` → `terraform apply -auto-approve`

### Azure Backend Bootstrap

```bash
# Run before terraform init in terraform_apply.yml
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="tfstatemoad${SUFFIX}"   # must be globally unique
CONTAINER="tfstate"

az group create --name $RESOURCE_GROUP --location westeurope
az storage account create \
  --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP \
  --sku Standard_LRS --allow-blob-public-access false
az storage container create \
  --name $CONTAINER --account-name $STORAGE_ACCOUNT

terraform init \
  -backend-config="resource_group_name=$RESOURCE_GROUP" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT" \
  -backend-config="container_name=$CONTAINER" \
  -backend-config="key=${ENV_NAME}/terraform.tfstate"
```

The `azurerm` backend has **built-in state locking** via Azure Blob Storage lease — no DynamoDB equivalent needed.

### GitHub Secrets Required

| Secret | Value from Pluralsight sandbox portal |
|---|---|
| `AZURE_CLIENT_ID` | Service Principal Application ID |
| `AZURE_CLIENT_SECRET` | Service Principal secret |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |

---

## 9. Terraform Module Structure

```
iac-repo/
├── .github/workflows/
│   ├── terraform_ci.yml
│   └── terraform_apply.yml
│
├── modules/
│   ├── vnet/                     # VNet + 3-tier subnets + NAT Gateways + NSGs
│   ├── private_endpoints/        # All Private Endpoints + Private DNS Zones
│   ├── storage/                  # Blob Storage: frontend (static site) + ml-data
│   ├── front_door/               # Azure Front Door Standard (CDN + WAF)
│   ├── application_gateway/      # App Gateway WAF v2 (API entry, routes to AKS)
│   ├── aks/                      # AKS cluster (Azure CNI, Workload Identity)
│   ├── acr/                      # Azure Container Registry (Premium for PE)
│   ├── cosmos_db/                # Cosmos DB NoSQL serverless (session history)
│   ├── ai_search/                # Azure AI Search Basic SKU (sandbox: Free or Basic only)
│   ├── key_vault/                # Azure Key Vault (secrets, endpoint URLs)
│   ├── azure_ml/                 # Azure ML Workspace + Compute Cluster + Online Endpoint
│   ├── azure_openai/             # Azure OpenAI: gpt-4o + text-embedding-3-small
│   └── monitoring/               # Log Analytics Workspace + Azure Monitor
│
├── environments/
│   ├── preprod.tfvars
│   └── prod.tfvars
│
├── main.tf
└── variables.tf
```

---

## 10. Environment Configuration

### `environments/preprod.tfvars`

```hcl
env      = "preprod"
location = "eastus"

vnet_cidr             = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.100.0/24", "10.0.101.0/24"]
private_subnet_cidrs  = ["10.0.0.0/24",   "10.0.1.0/24"]
database_subnet_cidrs = ["10.0.200.0/24", "10.0.201.0/24"]

aks_node_vm_size      = "Standard_DS2_v2"
aks_node_count_min    = 1
aks_node_count_max    = 2

# Sandbox: Free or Basic only (service-restrictions.md — Azure AI Search)
search_sku            = "basic"

ml_compute_vm_size    = "Standard_DS2_v2"
ml_compute_max_nodes  = 2

openai_gpt_model             = "gpt-4o"
openai_embedding_model       = "text-embedding-3-small"
openai_gpt_capacity_tpu      = 10
openai_embedding_capacity_tpu = 20
```

### `environments/prod.tfvars`

```hcl
env      = "prod"
location = "eastus"

vnet_cidr             = "10.1.0.0/16"
public_subnet_cidrs   = ["10.1.100.0/24", "10.1.101.0/24"]
private_subnet_cidrs  = ["10.1.0.0/24",   "10.1.1.0/24"]
database_subnet_cidrs = ["10.1.200.0/24", "10.1.201.0/24"]

aks_node_vm_size      = "Standard_DS2_v2"
aks_node_count_min    = 2
aks_node_count_max    = 4

# Sandbox: Free or Basic only (service-restrictions.md — Azure AI Search)
search_sku            = "basic"

ml_compute_vm_size    = "Standard_DS2_v2"
ml_compute_max_nodes  = 4

openai_gpt_model             = "gpt-4o"
openai_embedding_model       = "text-embedding-3-small"
openai_gpt_capacity_tpu      = 30
openai_embedding_capacity_tpu = 60
```

---

## 11. Sandbox Constraints & Bootstrap Strategy

### Pluralsight Azure AI Sandbox

| Constraint | Handling Strategy |
|---|---|
| 4-hour session | Terraform state persists in Azure Blob Storage across sessions — re-running `terraform apply` after a reset only recreates what was destroyed |
| New credentials each session | Update 4 GitHub Secrets → trigger `workflow_dispatch` on `terraform_apply.yml` |
| Azure OpenAI quota | Use `capacity_tpu` variables (10 TPM preprod, 30 TPM prod) — well within sandbox defaults |
| AKS provisioning (~10 min) | Trigger apply at the start of the session; other work continues while it provisions |
| Azure ML compute billing | Cluster scales to 0 nodes after 2 min idle — no cost between training runs |

### Provisioning Time Estimates (resources provision in parallel via Terraform)

| Resource | Time |
|---|---|
| VNet + Subnets + NSGs | ~1 min |
| Private Endpoints + DNS Zones | ~3 min |
| Blob Storage + ACR + Key Vault | ~2 min |
| AKS Cluster | ~10 min (critical path) |
| Cosmos DB (serverless) | ~3 min |
| Azure AI Search (S1) | ~5 min |
| Azure Functions (Premium EP1) | ~3 min |
| Azure ML Workspace | ~5 min |
| Azure OpenAI | ~2 min |
| Application Gateway (WAF v2) | ~5 min |
| Azure Front Door | ~3 min |
| **Total wall-clock (parallel)** | **~12–15 min** |

With a 4-hour session: ~15 min provisioning, ~45 min first ML training job, leaves ~3h for application deployment and end-to-end testing.

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────────────┐
│             INDUSTRIAL PREDICTIVE MAINTENANCE PLATFORM — AZURE               │
│                                                                               │
│  MAINTENANCE ENGINEER (browser)                                               │
│        │                                                                      │
│  [Azure Front Door — CDN + WAF]                                               │
│        ├── /static/*  → Azure Blob Storage (React dashboard)                 │
│        └── /api/*     → Application Gateway (WAF v2, public subnet)          │
│                              │                                                │
│                    ┌─────────▼──────────────────────────────────────────┐   │
│                    │         AZURE VNET 10.x.0.0/16                      │   │
│                    │                                                      │   │
│                    │  PRIVATE TIER                                        │   │
│                    │  AKS (FastAPI pod)                                   │   │
│                    │    ├── Fetch telemetry → Blob Storage                │   │
│                    │    ├── Predict failure → Azure ML Online Endpoint    │   │
│                    │    ├── Embed query   → Azure OpenAI (ada-3-small)    │   │
│                    │    ├── Search procedures → Azure AI Search (k-NN)   │   │
│                    │    ├── Generate answer → Azure OpenAI (GPT-4o)       │   │
│                    │    └── Save session  → Cosmos DB                     │   │
│                    │  Azure Functions (ingestion)                          │   │
│                    │    └── Blob Event → Chunk → Embed → AI Search index  │   │
│                    │                                                      │   │
│                    │  DATABASE TIER (Private Endpoints)                   │   │
│                    │  Cosmos DB │ AI Search │ Blob Storage                │   │
│                    │  Key Vault │ Azure ML │ ACR                        │   │
│                    └──────────────────────────────────────────────────────┘  │
│                                                                               │
│  MLOPS (Azure Machine Learning)                                               │
│  Kaggle CSV → Data Asset → Training Job (XGBoost + MLflow)                   │
│           → Model Registry (versioned) → Online Endpoint (Blue/Green)        │
│                                                                               │
│  LLMOPS                                                                       │
│  Markdown procedures (Git) → Blob sync → Azure Function → chunk/embed        │
│           → Azure AI Search (vector index, filtered by failure_type)          │
│  Prompts (Git) → Blob Storage versioned → FastAPI hot-reload                 │
└─────────────────────────────────────────────────────────────────────────────┘
```
