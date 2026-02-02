# Example configuration for Phase 3 - AI Foundry Deployment
# Copy this file to terraform.tfvars and update with your values

# Azure subscription configuration
resource_group_name_resources = "SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP"
subscription_id_resources     = "d664c605-3027-4933-8389-616fff76ecef"
location                      = "canadaeast"

# Federal Government Naming Convention
environment     = "dev"      # Options: "dev" or "prod"
department      = "ebida"    # Your department/project code
instance_number = "01"       # Instance number (must match Phase 1)

# Network configuration (from Phase 2 / networking team)
subnet_id_agent = ""

# Model deployment configuration (optional - defaults provided)
gpt_model_name     = "gpt-4o"       # Model name
gpt_model_version  = "2024-11-20"   # Model version
gpt_model_capacity = 1              # Capacity in TPM units
