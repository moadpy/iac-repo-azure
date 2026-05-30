# Microsoft Entra ID (Azure AD) Manual Application Setup

This guide explains how to manually create the required Microsoft Entra ID (Azure AD) applications. This is necessary because sandbox Service Principals do not have directory-level permissions to register applications dynamically through Terraform.

---

## 🔑 Required Applications

You need to create **two** App Registrations in the Azure Portal.

### 1. Backend Application (`rca-backend-app-preprod`)
* **Purpose**: Used by the FastAPI backend running in AKS to access Azure services (OpenAI, AI Search, Cosmos DB) securely using Workload Identity.
* **How to create**:
  1. Go to **Microsoft Entra ID** > **App registrations** > **New registration**.
  2. Name it: `rca-backend-app-preprod`.
  3. Select **Accounts in this organizational directory only** (Single tenant).
  4. Leave Redirect URI blank and click **Register**.
  5. Under **Certificates & secrets** > **Federated credentials**, click **Add credential**:
     * **Federated credential scenario**: `Kubernetes accessing Azure resources`
     * **Issuer**: (Use the OIDC Issuer URL outputted by Terraform: `AKS_OIDC_ISSUER_URL`)
     * **Subject identifier**: `system:serviceaccount:rca-dev:rca-backend`
     * **Name**: `rca-backend-federated-identity`
     * Click **Add**.

### 2. GitHub Actions/MLOps Application (`sp-mlops-github-actions-preprod`)
* **Purpose**: Used by MLOps workflows to train models and sync data blobs to the storage account.
* **How to create**:
  1. Go to **Microsoft Entra ID** > **App registrations** > **New registration**.
  2. Name it: `sp-mlops-github-actions-preprod`.
  3. Select **Accounts in this organizational directory only** (Single tenant) and click **Register**.
  4. Under **Certificates & secrets** > **Client secrets**, click **New client secret**.
  5. Add a description, set expiration (e.g., 180 days), and click **Add**.
  6. **Copy the Secret Value** immediately (you will need it for `github_actions_client_secret`).

---

## 📝 Values to Collect

Once created, collect the following values for your environment (e.g., `preprod`):

| Value Name | Description | Where to find in Azure Portal |
| :--- | :--- | :--- |
| **`backend_client_id`** | Application ID of the Backend App | App registration > Overview > **Application (client) ID** |
| **`backend_sp_object_id`** | Object ID of the *Service Principal* | Go to **Enterprise Applications** > Search for `rca-backend-app-preprod` > Copy the **Object ID** (⚠️ Do not use the App Registration Object ID) |
| **`github_actions_client_id`** | Application ID of the GitHub Actions App | App registration > Overview > **Application (client) ID** |
| **`github_actions_sp_object_id`** | Object ID of the *Service Principal* | Go to **Enterprise Applications** > Search for `sp-mlops-github-actions-preprod` > Copy the **Object ID** |
| **`github_actions_client_secret`**| Client Secret of the GitHub Actions App | App registration > Certificates & secrets > **Value** |

---

## ⚙️ Configuration in Terraform

After collecting these values, add them to your `environments/preprod.tfvars` file:

```hcl
backend_client_id            = "<backend_client_id>"
backend_sp_object_id         = "<backend_sp_object_id>"
github_actions_client_id     = "<github_actions_client_id>"
github_actions_sp_object_id  = "<github_actions_sp_object_id>"
github_actions_client_secret = "<github_actions_client_secret>"
```
Terraform will read these values and automatically configure all the Azure Role Assignments (RBAC) and Key Vault Access Policies for these identities without trying to create the applications itself.
