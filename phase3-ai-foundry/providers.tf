# Setup providers for Phase 3 - AI Foundry Deployment
# Assumes Phase 1 (Data Stores) and Phase 2 (Networking) are complete

provider "azapi" {
  subscription_id = var.subscription_id_resources
}

provider "azurerm" {
  subscription_id = var.subscription_id_resources
  features {}
  storage_use_azuread = true
}
