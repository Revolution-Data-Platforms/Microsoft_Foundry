# Outputs from Phase 3 - AI Foundry Deployment

## AI Foundry Account outputs
##
output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry Account"
  value       = azapi_resource.ai_foundry.id
}

output "ai_foundry_name" {
  description = "The name of the AI Foundry Account"
  value       = azapi_resource.ai_foundry.name
}

output "ai_foundry_endpoint" {
  description = "The endpoint URL for the AI Foundry Account"
  value       = "https://${azapi_resource.ai_foundry.name}.cognitiveservices.azure.com/"
}

## AI Foundry Project outputs
##
output "ai_foundry_project_id" {
  description = "The resource ID of the AI Foundry Project"
  value       = azapi_resource.ai_foundry_project.id
}

output "ai_foundry_project_name" {
  description = "The name of the AI Foundry Project"
  value       = azapi_resource.ai_foundry_project.name
}

output "ai_foundry_project_principal_id" {
  description = "The managed identity principal ID of the AI Foundry Project"
  value       = azapi_resource.ai_foundry_project.output.identity.principalId
  sensitive   = true
}

output "ai_foundry_project_internal_id" {
  description = "The internal ID of the AI Foundry Project"
  value       = azapi_resource.ai_foundry_project.output.properties.internalId
}

output "project_id_guid" {
  description = "The project ID formatted as GUID (used for Cosmos DB collection naming)"
  value       = local.project_id_guid
}

## Model deployment outputs
##
output "gpt_deployment_name" {
  description = "The name of the GPT model deployment"
  value       = azurerm_cognitive_deployment.aifoundry_deployment_gpt_4o.name
}

output "gpt_model_version" {
  description = "The version of the GPT model deployed"
  value       = azurerm_cognitive_deployment.aifoundry_deployment_gpt_4o.model[0].version
}

## Capability Host output
##
output "capability_host_id" {
  description = "The resource ID of the Agents capability host"
  value       = azapi_resource.ai_foundry_project_capability_host.id
}

## Connection outputs
##
output "connections" {
  description = "Summary of project connections"
  value = {
    cosmosdb = azapi_resource.conn_cosmosdb.name
    storage  = azapi_resource.conn_storage.name
    aisearch = azapi_resource.conn_aisearch.name
  }
}

## Deployment summary
##
output "deployment_summary" {
  description = "Summary of the deployed AI Foundry infrastructure"
  value = {
    environment      = var.environment
    department       = var.department
    instance_number  = var.instance_number
    resource_group   = var.resource_group_name_resources
    location         = var.location
    ai_foundry_name  = azapi_resource.ai_foundry.name
    project_name     = azapi_resource.ai_foundry_project.name
    model_deployment = azurerm_cognitive_deployment.aifoundry_deployment_gpt_4o.name
    phase            = "Phase3-Complete"
  }
}
