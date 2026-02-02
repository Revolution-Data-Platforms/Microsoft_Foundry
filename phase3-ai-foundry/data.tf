# Data sources to reference resources created in Phase 1
# These resources must exist before deploying Phase 3

## Storage Account from Phase 1
##
data "azurerm_storage_account" "storage_account" {
  name                = local.storage_name
  resource_group_name = var.resource_group_name_resources
}

## Cosmos DB Account from Phase 1
##
data "azurerm_cosmosdb_account" "cosmosdb" {
  name                = local.cosmosdb_name
  resource_group_name = var.resource_group_name_resources
}

## AI Search from Phase 1
##
data "azapi_resource" "ai_search" {
  type      = "Microsoft.Search/searchServices@2025-05-01"
  name      = local.aisearch_name
  parent_id = "/subscriptions/${var.subscription_id_resources}/resourceGroups/${var.resource_group_name_resources}"
}
