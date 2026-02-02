########## Phase 3: AI Foundry Deployment
##########
## This phase deploys:
## - Azure AI Foundry Account (with VNet injection)
## - GPT-4o Model Deployment
## - AI Foundry Project
## - Service Connections (Cosmos DB, Storage, AI Search)
## - RBAC Role Assignments
## - Project Capability Host (Agents)
## - Cosmos DB SQL Role Assignments
##
## Prerequisites:
## - Phase 1 complete (Data Stores deployed)
## - Phase 2 complete (Private Endpoints configured)
## - Same naming convention values from Phase 1
##########

########## Create AI Foundry Account
##########

## Create the AI Foundry Account with VNet injection
##
resource "azapi_resource" "ai_foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = local.aifoundry_name
  parent_id = "/subscriptions/${var.subscription_id_resources}/resourceGroups/${var.resource_group_name_resources}"
  location  = var.location

  schema_validation_enabled = false

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      # Support both Entra ID and API Key authentication for underlying Cognitive Services account
      disableLocalAuth = false

      # Specifies that this is an AI Foundry resource
      allowProjectManagement = true

      # Set custom subdomain name for DNS names created for this Foundry resource
      customSubDomainName = local.aifoundry_name

      # Network-related controls
      # Disable public access but allow Trusted Azure Services exception
      publicNetworkAccess = "Disabled"
      networkAcls = {
        defaultAction = "Allow"
      }

      # Enable VNet injection for Standard Agents
      networkInjections = [
        {
          scenario                   = "agent"
          subnetArmId                = var.subnet_id_agent
          useMicrosoftManagedNetwork = false
        }
      ]
    }

    tags = local.common_tags
  }
}

## Create a deployment for OpenAI's GPT-4o in the AI Foundry Account
##
resource "azurerm_cognitive_deployment" "aifoundry_deployment_gpt_4o" {
  depends_on = [
    azapi_resource.ai_foundry
  ]

  name                 = var.gpt_model_name
  cognitive_account_id = azapi_resource.ai_foundry.id

  sku {
    name     = "GlobalStandard"
    capacity = var.gpt_model_capacity
  }

  model {
    format  = "OpenAI"
    name    = var.gpt_model_name
    version = var.gpt_model_version
  }
}

########## Create AI Foundry Project
##########

## Create AI Foundry Project
##
resource "azapi_resource" "ai_foundry_project" {
  depends_on = [
    azapi_resource.ai_foundry
  ]

  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = local.project_name
  parent_id = azapi_resource.ai_foundry.id
  location  = var.location

  schema_validation_enabled = false

  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      displayName = local.project_name
      description = "AI Foundry project with network-secured deployed Agent for ${var.department}"
    }

    tags = local.common_tags
  }

  response_export_values = [
    "identity.principalId",
    "properties.internalId"
  ]
}

## Wait 10 seconds for the AI Foundry project system-assigned managed identity to be created
## and to replicate through Entra ID
##
resource "time_sleep" "wait_project_identities" {
  depends_on = [
    azapi_resource.ai_foundry_project
  ]
  create_duration = "10s"
}

########## Create AI Foundry Project Connections
##########

## Create AI Foundry project connection to Cosmos DB
##
resource "azapi_resource" "conn_cosmosdb" {
  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = data.azurerm_cosmosdb_account.cosmosdb.name
  parent_id = azapi_resource.ai_foundry_project.id

  schema_validation_enabled = false

  body = {
    name = data.azurerm_cosmosdb_account.cosmosdb.name
    properties = {
      category = "CosmosDb"
      target   = data.azurerm_cosmosdb_account.cosmosdb.endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = data.azurerm_cosmosdb_account.cosmosdb.id
        location   = var.location
      }
    }
  }
}

## Create the AI Foundry project connection to Azure Storage Account
##
resource "azapi_resource" "conn_storage" {
  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = data.azurerm_storage_account.storage_account.name
  parent_id = azapi_resource.ai_foundry_project.id

  schema_validation_enabled = false

  body = {
    name = data.azurerm_storage_account.storage_account.name
    properties = {
      category = "AzureStorageAccount"
      target   = data.azurerm_storage_account.storage_account.primary_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = data.azurerm_storage_account.storage_account.id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

## Create the AI Foundry project connection to AI Search
##
resource "azapi_resource" "conn_aisearch" {
  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = data.azapi_resource.ai_search.name
  parent_id = azapi_resource.ai_foundry_project.id

  schema_validation_enabled = false

  body = {
    name = data.azapi_resource.ai_search.name
    properties = {
      category = "CognitiveSearch"
      target   = "https://${data.azapi_resource.ai_search.name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2025-05-01-preview"
        ResourceId = data.azapi_resource.ai_search.id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

########## Create RBAC Role Assignments
##########

## Cosmos DB Operator role for AI Foundry Project
##
resource "azurerm_role_assignment" "cosmosdb_operator_ai_foundry_project" {
  depends_on = [
    resource.time_sleep.wait_project_identities
  ]

  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}${var.resource_group_name_resources}cosmosdboperator")
  scope                = data.azurerm_cosmosdb_account.cosmosdb.id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId
}

## Storage Blob Data Contributor role for AI Foundry Project
##
resource "azurerm_role_assignment" "storage_blob_data_contributor_ai_foundry_project" {
  depends_on = [
    resource.time_sleep.wait_project_identities
  ]

  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}${data.azurerm_storage_account.storage_account.name}storageblobdatacontributor")
  scope                = data.azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId
}

## Search Index Data Contributor role for AI Foundry Project
##
resource "azurerm_role_assignment" "search_index_data_contributor_ai_foundry_project" {
  depends_on = [
    resource.time_sleep.wait_project_identities
  ]

  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}${data.azapi_resource.ai_search.name}searchindexdatacontributor")
  scope                = data.azapi_resource.ai_search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId
}

## Search Service Contributor role for AI Foundry Project
##
resource "azurerm_role_assignment" "search_service_contributor_ai_foundry_project" {
  depends_on = [
    resource.time_sleep.wait_project_identities
  ]

  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}${data.azapi_resource.ai_search.name}searchservicecontributor")
  scope                = data.azapi_resource.ai_search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId
}

## Pause 60 seconds to allow for role assignments to propagate through Azure AD
##
resource "time_sleep" "wait_rbac" {
  depends_on = [
    azurerm_role_assignment.cosmosdb_operator_ai_foundry_project,
    azurerm_role_assignment.storage_blob_data_contributor_ai_foundry_project,
    azurerm_role_assignment.search_index_data_contributor_ai_foundry_project,
    azurerm_role_assignment.search_service_contributor_ai_foundry_project
  ]
  create_duration = "60s"
}

########## Create AI Foundry Project Capability Host (Agents)
##########

## Create the AI Foundry project capability host for Agents
##
resource "azapi_resource" "ai_foundry_project_capability_host" {
  depends_on = [
    azapi_resource.conn_aisearch,
    azapi_resource.conn_cosmosdb,
    azapi_resource.conn_storage,
    time_sleep.wait_rbac
  ]

  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  name      = "caphostproj"
  parent_id = azapi_resource.ai_foundry_project.id

  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
      vectorStoreConnections = [
        data.azapi_resource.ai_search.name
      ]
      storageConnections = [
        data.azurerm_storage_account.storage_account.name
      ]
      threadStorageConnections = [
        data.azurerm_cosmosdb_account.cosmosdb.name
      ]
    }
  }
}

########## Create Cosmos DB Data Plane Role Assignments
##########

## Cosmos DB SQL role assignment for user thread message store
##
resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_user_thread_message_store" {
  depends_on = [
    azapi_resource.ai_foundry_project_capability_host
  ]

  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}userthreadmessage_dbsqlrole")
  resource_group_name = var.resource_group_name_resources
  account_name        = data.azurerm_cosmosdb_account.cosmosdb.name
  scope               = "${data.azurerm_cosmosdb_account.cosmosdb.id}/dbs/enterprise_memory/colls/${local.project_id_guid}-thread-message-store"
  role_definition_id  = "${data.azurerm_cosmosdb_account.cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project.output.identity.principalId
}

## Cosmos DB SQL role assignment for system thread message store
##
resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_system_thread_name" {
  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.cosmosdb_db_sql_role_aifp_user_thread_message_store
  ]

  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}systemthread_dbsqlrole")
  resource_group_name = var.resource_group_name_resources
  account_name        = data.azurerm_cosmosdb_account.cosmosdb.name
  scope               = "${data.azurerm_cosmosdb_account.cosmosdb.id}/dbs/enterprise_memory/colls/${local.project_id_guid}-system-thread-message-store"
  role_definition_id  = "${data.azurerm_cosmosdb_account.cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project.output.identity.principalId
}

## Cosmos DB SQL role assignment for entity store
##
resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_entity_store_name" {
  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.cosmosdb_db_sql_role_aifp_system_thread_name
  ]

  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}entitystore_dbsqlrole")
  resource_group_name = var.resource_group_name_resources
  account_name        = data.azurerm_cosmosdb_account.cosmosdb.name
  scope               = "${data.azurerm_cosmosdb_account.cosmosdb.id}/dbs/enterprise_memory/colls/${local.project_id_guid}-agent-entity-store"
  role_definition_id  = "${data.azurerm_cosmosdb_account.cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project.output.identity.principalId
}

## Storage Blob Data Owner role for AI Foundry Project (container-level)
## This provides full access to storage containers created by the capability host
##
resource "azurerm_role_assignment" "storage_blob_data_owner_ai_foundry_project" {
  depends_on = [
    azapi_resource.ai_foundry_project_capability_host
  ]

  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${azapi_resource.ai_foundry_project.output.identity.principalId}${data.azurerm_storage_account.storage_account.name}storageblobdataowner")
  scope                = data.azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azapi_resource.ai_foundry_project.output.identity.principalId
}
