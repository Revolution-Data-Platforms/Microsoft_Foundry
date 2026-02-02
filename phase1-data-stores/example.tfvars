# Example configuration for Phase 1 - Data Stores Deployment
# Copy this file to terraform.tfvars and update with your values

# Azure subscription configuration
resource_group_name_resources = ""
subscription_id_resources     = ""
location                      = ""

environment     = "dev"           # Options: "dev" or "prod"
department      = ""         
instance_number = ""            # Instance number (2 digits: 01, 02, etc.)
