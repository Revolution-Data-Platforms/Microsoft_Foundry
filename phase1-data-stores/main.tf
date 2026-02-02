########## Phase 1: Data Stores Deployment
##########
## This phase deploys:
## - Azure Storage Account (for agent data and blobs)
## - Azure Cosmos DB for NoSQL (for threads and messages)
## - Azure AI Search (for vector embeddings and RAG)
##
## Naming Convention: Federal Government Standards
## - Environment prefix: dev=scned, prod=scped
## - Format: <prefix>-<department>-<service>-<instance>
## - Storage: <prefix><department>sa<instance> (no dashes)
##
## Note: Network restrictions will be applied in Phase 2 by the networking team
##########

########## Create resources required for agent data storage
##########

## Create a storage account for agent data
##
resource "azurerm_storage_account" "storage_account" {
  name                = local.storage_name
  resource_group_name = var.resource_group_name_resources
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  ## Identity configuration
  shared_access_key_enabled = false

  ## Network access configuration
  ## Public network access is DISABLED from deployment
  ## Phase 2: Networking team will add private endpoints for connectivity
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = "Deny"
    bypass = [
      "AzureServices"
    ]
  }

  tags = local.common_tags
}

## Create the Cosmos DB account to store agent threads
##
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = local.cosmosdb_name
  location            = var.location
  resource_group_name = var.resource_group_name_resources

  # General settings
  offer_type        = "Standard"
  kind              = "GlobalDocumentDB"
  free_tier_enabled = false

  # Security settings
  ## Public network access is DISABLED from deployment
  ## Phase 2: Networking team will add private endpoints for connectivity
  local_authentication_disabled = true
  public_network_access_enabled = false

  # Set high availability and failover settings
  automatic_failover_enabled       = false
  multiple_write_locations_enabled = false

  # Configure consistency settings
  consistency_policy {
    consistency_level = "Session"
  }

  # Configure single location with no zone redundancy to reduce costs
  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  tags = local.common_tags
}

## Create an AI Search instance for vector embeddings
##
resource "azapi_resource" "ai_search" {
  type      = "Microsoft.Search/searchServices@2025-05-01"
  name      = local.aisearch_name
  parent_id = "/subscriptions/${var.subscription_id_resources}/resourceGroups/${var.resource_group_name_resources}"
  location  = var.location

  schema_validation_enabled = true

  body = {
    sku = {
      name = "standard"
    }

    identity = {
      type = "SystemAssigned"
    }

    properties = {
      # Search-specific properties
      replicaCount   = 1
      partitionCount = 1
      hostingMode    = "Default"
      semanticSearch = "disabled"

      # Identity-related controls
      disableLocalAuth = false
      authOptions = {
        aadOrApiKey = {
          aadAuthFailureMode = "http401WithBearerChallenge"
        }
      }

      # Network security settings
      ## Public network access is DISABLED from deployment
      ## Phase 2: Networking team will add private endpoints for connectivity
      publicNetworkAccess = "Disabled"
      networkRuleSet = {
        bypass = "None"
      }
    }

    tags = local.common_tags
  }
}
