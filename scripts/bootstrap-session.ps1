#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap script for Pluralsight sandbox sessions.

.DESCRIPTION
    Run this script ONCE at the start of every new Pluralsight sandbox session.
    It updates the 4 rotating GitHub Secrets with the credentials from the
    Pluralsight lab portal, so all pipelines authenticate correctly.

    Prerequisites:
      - GitHub CLI installed and authenticated: gh auth login
      - Azure CLI installed and accessible in PATH

.PARAMETER ClientId
    Azure Service Principal Application (Client) ID from the lab portal.

.PARAMETER ClientSecret
    Azure Service Principal secret/password from the lab portal.

.PARAMETER SubscriptionId
    Azure Subscription ID from the lab portal.

.PARAMETER TenantId
    Azure Tenant (Directory) ID from the lab portal.

.PARAMETER Repo
    GitHub repository in "org/repo" format. Defaults to the current repo via gh CLI.

.EXAMPLE
    .\scripts\bootstrap-session.ps1 `
        -ClientId     "a1b2c3d4-0000-0000-0000-111111111111" `
        -ClientSecret "MySecretPassword123!" `
        -SubscriptionId "sub-0000-0000-0000-000000000000" `
        -TenantId     "tenant-0000-0000-0000-000000000000"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$ClientSecret,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string]$Repo = ""
)

$ErrorActionPreference = "Stop"

# ---------- Resolve repo name ------------------------------------------------
if ([string]::IsNullOrEmpty($Repo)) {
    try {
        $Repo = gh repo view --json nameWithOwner -q .nameWithOwner 2>$null
    } catch {
        Write-Error "Could not determine GitHub repository. Pass -Repo 'your-org/iac-repo-azure'."
        exit 1
    }
}

if ([string]::IsNullOrEmpty($Repo)) {
    Write-Error "Repository name is empty. Run from a git repo or pass -Repo 'org/repo'."
    exit 1
}

# ---------- Check prerequisites ----------------------------------------------
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI 'gh' is not installed. Install from: https://cli.github.com"
    exit 1
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI 'az' is not installed. Install from: https://aka.ms/installazurecliwindows"
    exit 1
}

# Check gh is authenticated
$ghStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "GitHub CLI is not authenticated. Run: gh auth login"
    exit 1
}

# ---------- Update GitHub Secrets --------------------------------------------
Write-Host ""
Write-Host "Updating GitHub Secrets for repo: $Repo" -ForegroundColor Cyan
Write-Host ("─" * 50) -ForegroundColor DarkGray

function Set-GitHubSecret {
    param([string]$Name, [string]$Value)
    Write-Host "  Setting $Name ... " -NoNewline
    $Value | gh secret set $Name --repo $Repo --body -
    if ($LASTEXITCODE -eq 0) {
        Write-Host "done" -ForegroundColor Green
    } else {
        Write-Host "FAILED" -ForegroundColor Red
        exit 1
    }
}

Set-GitHubSecret -Name "ARM_CLIENT_ID"       -Value $ClientId
Set-GitHubSecret -Name "ARM_CLIENT_SECRET"   -Value $ClientSecret
Set-GitHubSecret -Name "ARM_SUBSCRIPTION_ID" -Value $SubscriptionId
Set-GitHubSecret -Name "ARM_TENANT_ID"       -Value $TenantId

# ---------- Verify Azure login -----------------------------------------------
Write-Host ""
Write-Host "Verifying Azure login with new credentials..." -ForegroundColor Cyan

az login --service-principal `
    --username $ClientId `
    --password $ClientSecret `
    --tenant   $TenantId `
    --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure login FAILED. Check your credentials." -ForegroundColor Red
    exit 1
}

$accountName = az account show --query name -o tsv
$rgName      = az group list --query "[0].name" -o tsv 2>$null
if ([string]::IsNullOrEmpty($rgName)) { $rgName = "none found" }

# ---------- Summary ----------------------------------------------------------
Write-Host ""
Write-Host ("─" * 50) -ForegroundColor DarkGray
Write-Host "SUCCESS — Session bootstrap complete" -ForegroundColor Green
Write-Host ""
Write-Host "  Repository:      $Repo"
Write-Host "  Client ID:       $ClientId"
Write-Host "  Subscription ID: $SubscriptionId"
Write-Host "  Tenant ID:       $TenantId"
Write-Host "  Account:         $accountName"
Write-Host "  Resource Group:  $rgName"
Write-Host ""
Write-Host "Next step: trigger the infrastructure pipeline" -ForegroundColor Yellow
Write-Host "  gh workflow run terraform_apply.yml --repo $Repo --field environment=preprod"
Write-Host ""
Write-Host "Or open GitHub Actions in your browser:"
Write-Host "  gh repo view $Repo --web"
Write-Host ("─" * 50) -ForegroundColor DarkGray
