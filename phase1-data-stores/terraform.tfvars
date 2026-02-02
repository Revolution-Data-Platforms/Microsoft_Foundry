# Example configuration for Phase 1 - Data Stores Deployment
# Copy this file to terraform.tfvars and update with your values

# Azure subscription configuration
resource_group_name_resources = "AI-resources"
subscription_id_resources     = "cb4417ae-db8d-4aa2-b4ff-e44862cb6b9b"
location                      = "canadaeast"

environment     = "dev"           # Options: "dev" or "prod"
department      = "ebida"         
instance_number = "01"            # Instance number (2 digits: 01, 02, etc.)

# This will create resources with names:
# - AI Foundry: scned-ebida-aifoundry-01
# - AI Search: scned-ebida-search-01
# - Cosmos DB: scned-ebida-cosmos-01
# - Storage: scnedebidasa01
