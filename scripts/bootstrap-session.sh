#!/usr/bin/env bash
# =============================================================================
# bootstrap-session.sh
# =============================================================================
# Run this script ONCE at the start of every new Pluralsight sandbox session.
# It updates the 4 rotating GitHub Secrets with the credentials from the
# Pluralsight lab portal, so all pipelines authenticate correctly.
#
# Prerequisites:
#   - GitHub CLI installed and authenticated: gh auth login
#   - jq installed (for validation)
#
# Usage:
#   ./scripts/bootstrap-session.sh \
#     <CLIENT_ID> <CLIENT_SECRET> <SUBSCRIPTION_ID> <TENANT_ID>
#
# Example:
#   ./scripts/bootstrap-session.sh \
#     "a1b2c3d4-..." "MySecret123!" "sub-1234-..." "tenant-5678-..."
# =============================================================================

set -euo pipefail

# ---------- Inputs -----------------------------------------------------------
CLIENT_ID="${1:-}"
CLIENT_SECRET="${2:-}"
SUBSCRIPTION_ID="${3:-}"
TENANT_ID="${4:-}"

# ---------- Config -----------------------------------------------------------
# Change this to your actual GitHub org/repo
REPO="${GITHUB_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '')}"

# ---------- Validation -------------------------------------------------------
if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$SUBSCRIPTION_ID" || -z "$TENANT_ID" ]]; then
  echo "ERROR: All 4 arguments are required."
  echo ""
  echo "Usage: $0 <CLIENT_ID> <CLIENT_SECRET> <SUBSCRIPTION_ID> <TENANT_ID>"
  echo ""
  echo "Find these values in the Pluralsight lab portal under 'Azure Credentials'."
  exit 1
fi

if [[ -z "$REPO" ]]; then
  echo "ERROR: Could not determine GitHub repository."
  echo "Either run from inside a git repo with 'gh' configured, or set:"
  echo "  export GITHUB_REPO=your-org/iac-repo-azure"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "ERROR: GitHub CLI 'gh' is not installed."
  echo "Install: https://cli.github.com"
  exit 1
fi

# ---------- Verify gh is authenticated ---------------------------------------
if ! gh auth status &>/dev/null; then
  echo "ERROR: GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

# ---------- Update secrets ---------------------------------------------------
echo ""
echo "Updating GitHub Secrets for repo: $REPO"
echo "──────────────────────────────────────────"

update_secret() {
  local name="$1"
  local value="$2"
  echo -n "  Setting $name ... "
  echo "$value" | gh secret set "$name" --repo "$REPO" --body -
  echo "done"
}

update_secret "ARM_CLIENT_ID"       "$CLIENT_ID"
update_secret "ARM_CLIENT_SECRET"   "$CLIENT_SECRET"
update_secret "ARM_SUBSCRIPTION_ID" "$SUBSCRIPTION_ID"
update_secret "ARM_TENANT_ID"       "$TENANT_ID"

# ---------- Verify Azure login works -----------------------------------------
echo ""
echo "Verifying Azure login with new credentials..."
az login --service-principal \
  --username    "$CLIENT_ID" \
  --password    "$CLIENT_SECRET" \
  --tenant      "$TENANT_ID" \
  --output none

ACCOUNT_NAME=$(az account show --query name -o tsv)
RG=$(az group list --query "[0].name" -o tsv 2>/dev/null || echo "none found")

echo ""
echo "──────────────────────────────────────────"
echo "SUCCESS — Session bootstrap complete"
echo ""
echo "  Repository:      $REPO"
echo "  Client ID:       $CLIENT_ID"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo "  Tenant ID:       $TENANT_ID"
echo "  Account:         $ACCOUNT_NAME"
echo "  Resource Group:  $RG"
echo ""
echo "Next step: trigger the infrastructure pipeline"
echo "  gh workflow run terraform_apply.yml --repo $REPO \\"
echo "    --field environment=preprod"
echo ""
echo "Or open GitHub Actions in your browser:"
echo "  gh repo view $REPO --web"
echo "──────────────────────────────────────────"
