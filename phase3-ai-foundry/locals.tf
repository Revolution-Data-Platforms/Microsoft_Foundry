# Local values for Phase 3 naming convention
# MUST use the same values as Phase 1 for consistency

locals {
  # Map environment to prefix (must match Phase 1)
  environment_prefix = var.environment == "dev" ? "scned" : "scped"

  # Resource naming following federal standards
  naming_prefix = "${local.environment_prefix}-${var.department}"

  # AI Foundry naming: scned-ebida-aifoundry-01
  aifoundry_name = "${local.naming_prefix}-aifoundry-${var.instance_number}"

  # AI Foundry Project naming: scned-ebida-project-01
  project_name = "${local.naming_prefix}-project-${var.instance_number}"

  # Storage Account naming (from Phase 1): scnedebidasa01
  storage_name = "${local.environment_prefix}${var.department}sa${var.instance_number}"

  # Cosmos DB naming (from Phase 1): scned-ebida-cosmos-01
  cosmosdb_name = "${local.naming_prefix}-cosmos-${var.instance_number}"

  # AI Search naming (from Phase 1): scned-ebida-search-01
  aisearch_name = "${local.naming_prefix}-search-${var.instance_number}"

  # Extract project internal ID as GUID for Cosmos DB collection naming
  # This is computed after project creation
  project_id_guid = "${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 0, 8)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 8, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 12, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 16, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 20, 12)}"

  # Common tags for all resources
  common_tags = {
    Department = var.department
    ManagedBy  = "Terraform"
    Phase      = "ai_foundry"
  }
}
