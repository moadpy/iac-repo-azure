# scripts/setup-state.ps1
# Requires you to run .\prog-login.ps1 first!

$ErrorActionPreference = "Stop"

$RG = $env:TF_VAR_resource_group_name
$SUB_ID = $env:ARM_SUBSCRIPTION_ID

if ([string]::IsNullOrWhiteSpace($RG) -or [string]::IsNullOrWhiteSpace($SUB_ID)) {
    Write-Error "Missing environment variables. Please run .\prog-login.ps1 first!"
    exit 1
}

# Generate a random string (10 characters: lowercase letters and numbers)
$randomString = -join ((97..122) + (48..57) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
$SA_NAME = "tfstate$randomString"

Write-Host "--- Bootstrapping Terraform Remote State ---" -ForegroundColor Cyan
Write-Host "Target Resource Group : $RG"
Write-Host "New Storage Account   : $SA_NAME"

# Create the Storage Account
Write-Host "Creating Storage Account..."
az storage account create `
  --name $SA_NAME `
  --resource-group $RG `
  --sku Standard_LRS `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false `
  --output none

# Get the Access Key
Write-Host "Retrieving Access Key..."
$SA_KEY = az storage account keys list `
  --account-name $SA_NAME `
  --resource-group $RG `
  --query "[0].value" -o tsv

# Create the Blob Container
Write-Host "Creating 'tfstate' container..."
az storage container create `
  --name tfstate `
  --account-name $SA_NAME `
  --account-key $SA_KEY `
  --output none

# Export as session environment variables for Terraform
$env:TF_VAR_tf_state_storage_account = $SA_NAME
$env:TF_VAR_tf_state_access_key      = $SA_KEY

Write-Host "`n--- STATE BACKEND READY ---" -ForegroundColor Green
Write-Host "The following environment variables have been set for your current terminal session:"
Write-Host "TF_VAR_tf_state_storage_account = $env:TF_VAR_tf_state_storage_account"
Write-Host "TF_VAR_tf_state_access_key      = [SECRET]"
Write-Host "`nYou can now deploy the infrastructure."
