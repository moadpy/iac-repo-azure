# ===========================================================================
# Locals — Naming and tagging configuration
# ===========================================================================

locals {
  # Clean suffix for normal resources (just the environment name, e.g. "dev" or "prod")
  clean_suffix = var.environment

  # Globally unique suffix (environment + random string) for DNS/globally unique resources
  unique_suffix = "${var.environment}-${random_string.suffix.result}"

  # Dashless globally unique suffix for storage accounts / container registries
  unique_suffix_alphanumeric = "${var.environment}${random_string.suffix.result}"

  tags = {
    environment = var.environment
    project     = "predictive-maintenance"
    managed_by  = "terraform"
  }
}
