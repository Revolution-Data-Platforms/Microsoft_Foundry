# Outputs from Phase 1 - Data Stores
# These outputs will be used as inputs for Phase 2 (Networking) and Phase 3 (AI Foundry)

# Resource IDs for Private Endpoint creation in Phase 2
output "storage_account_id" {
  description = "The resource ID of the Storage Account"
  value       = azurerm_storage_account.storage_account.id
}

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.storage_account.name
}

output "cosmosdb_account_id" {
  description = "The resource ID of the Cosmos DB Account"
  value       = azurerm_cosmosdb_account.cosmosdb.id
}

output "cosmosdb_account_name" {
  description = "The name of the Cosmos DB Account"
  value       = azurerm_cosmosdb_account.cosmosdb.name
}

output "ai_search_id" {
  description = "The resource ID of the AI Search instance"
  value       = azapi_resource.ai_search.id
}

output "ai_search_name" {
  description = "The name of the AI Search instance"
  value       = azapi_resource.ai_search.name
}

# Naming convention outputs - CRITICAL for Phase 3
output "environment" {
  description = "The environment (dev/prod) - MUST use same value in Phase 3"
  value       = var.environment
}

output "department" {
  description = "The department name - MUST use same value in Phase 3"
  value       = var.department
}

output "instance_number" {
  description = "The instance number - MUST use same value in Phase 3"
  value       = var.instance_number
}

output "naming_prefix" {
  description = "The naming prefix used (e.g., scned-ebida)"
  value       = local.naming_prefix
}

output "aifoundry_name" {
  description = "The AI Foundry name that will be used in Phase 3"
  value       = local.aifoundry_name
}

# Deployment context
output "resource_group_name" {
  description = "The resource group name where resources were deployed"
  value       = var.resource_group_name_resources
}

output "location" {
  description = "The Azure region where resources were deployed"
  value       = var.location
}

output "subscription_id" {
  description = "The subscription ID where resources were deployed"
  value       = var.subscription_id_resources
}
