# Local values for naming convention
# Federal government naming standards

locals {
  # Map environment to prefix
  # dev -> scned (Secure Cloud Network Engineering Development)
  # prod -> scped (Secure Cloud Platform Engineering Production)
  environment_prefix = var.environment == "dev" ? "scned" : "scped"

  # Resource naming following federal standards
  # Format: <env-prefix>-<department>-<service>-<instance>

  naming_prefix = "${local.environment_prefix}-${var.department}"

  # AI Foundry naming: scned-ebida-aifoundry-01
  aifoundry_name = "${local.naming_prefix}-aifoundry-${var.instance_number}"

  # AI Search naming: scned-ebida-search-01
  aisearch_name = "${local.naming_prefix}-search-${var.instance_number}"

  # Cosmos DB naming: scned-ebida-cosmos-01
  cosmosdb_name = "${local.naming_prefix}-cosmos-${var.instance_number}"

  # Storage Account naming: scnedebidasa01
  # Storage accounts don't support dashes, must be lowercase alphanumeric only, 3-24 chars
  storage_name = "${local.environment_prefix}${var.department}sa${var.instance_number}"

  # Common tags for all resources
  common_tags = {
    Department  = var.department
    ManagedBy   = "Terraform"
    Phase       = "ai_foundry"
  }
}
