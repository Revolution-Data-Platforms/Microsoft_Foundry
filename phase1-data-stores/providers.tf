# Setup providers for Phase 1 - Data Stores
# Only needs access to workload subscription

provider "azapi" {
  subscription_id = var.subscription_id_resources
}

provider "azurerm" {
  subscription_id = var.subscription_id_resources
  features {}
  storage_use_azuread = true
}
