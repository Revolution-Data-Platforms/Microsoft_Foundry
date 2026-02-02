# Phase 1: Data Stores Deployment

This directory contains Terraform configuration for deploying **only the data stores** required for Azure AI Foundry Agents:

- **Azure Storage Account** (for agent data and blobs)
- **Azure Cosmos DB for NoSQL** (for threads and messages)
- **Azure AI Search** (for vector embeddings and RAG)

## Architecture

```
Phase 1 (You Deploy Now)
┌─────────────────────────────────────┐
│ Workload Subscription               │
│                                     │
│  ┌──────────────┐  ┌──────────────┐│
│  │ Storage      │  │ Cosmos DB    ││
│  │ Account      │  │ (NoSQL)      ││
│  └──────────────┘  └──────────────┘│
│                                     │
│  ┌──────────────┐                  │
│  │ AI Search    │                  │
│  │ (Standard)   │                  │
│  └──────────────┘                  │
│                                     │
│  🔒 Public Access: DISABLED         │
│  ⏳ Not accessible until Phase 2    │
└─────────────────────────────────────┘
```

## Why This Approach?

This phased deployment allows:
- ✅ **Your team** to deploy data stores immediately with secure defaults
- ✅ **Networking team** to add private endpoints independently (Phase 2)
- ✅ **You** to complete AI Foundry setup after networking (Phase 3)
- ✅ Clean separation of responsibilities and Terraform state
- 🔒 **Security first** - public access disabled from day one

## Prerequisites

1. **Azure Subscription** with permissions to create resources
2. **Resource Group** (must exist before deployment)
3. **Terraform** v1.10.0 or later installed
4. **Azure CLI** authenticated with appropriate permissions

## Deployment Steps

### 1. Authenticate to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Create Configuration File

```bash
cd phase1-data-stores
cp example.tfvars terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Azure configuration
resource_group_name_resources = "rg-scned-ebida-aifoundry-01"
subscription_id_resources     = "your-subscription-id"
location                      = "canadacentral"

# Federal Government Naming Convention
environment     = "dev"      # Options: "dev" or "prod"
department      = "ebida"    # Your department/project code
instance_number = "01"       # Instance number (01, 02, etc.)
```

This will create resources with names:
- AI Search: `scned-ebida-search-01`
- Cosmos DB: `scned-ebida-cosmos-01`
- Storage: `scnedebidasa01` (no dashes allowed in storage names)

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy resources
terraform apply
```

### 4. Capture Outputs

After deployment completes, save the outputs - you'll need them for Phase 3:

```bash
terraform output > ../phase1-outputs.txt
```

Key outputs:
- `storage_account_id` - Used by networking team for private endpoint
- `cosmosdb_account_id` - Used by networking team for private endpoint
- `ai_search_id` - Used by networking team for private endpoint
- `random_suffix` - **IMPORTANT**: Must use the same suffix in Phase 3

## What Gets Deployed?

### Storage Account
- **Name**: `scnedebidasa01` (or `scpedebidasa01` for prod)
- **Type**: StorageV2, Standard, ZRS
- **Network**: 🔒 Public access **DISABLED** (Deny all by default)
- **Auth**: Azure AD only (no shared keys)

### Cosmos DB Account
- **Name**: `scned-ebida-cosmos-01`
- **Type**: NoSQL, Standard tier
- **Network**: 🔒 Public access **DISABLED**
- **Auth**: Azure AD only (local auth disabled)
- **Consistency**: Session level

### AI Search
- **Name**: `scned-ebida-search-01`
- **Tier**: Standard (1 partition, 1 replica)
- **Network**: 🔒 Public access **DISABLED**
- **Auth**: Azure AD and API key (AAD challenge configured)

## Network Security Note

🔒 **Security First**: These resources are deployed with **public network access DISABLED** from the start.

**Important Implications**:
- ✅ Resources are created but **not accessible** until Phase 2 completes
- ✅ Terraform deployment will succeed even though resources aren't reachable
- ✅ No temporary security compromise - proper zero-trust from day one
- ⏳ Resources become accessible only after private endpoints are configured in Phase 2

After deployment:
1. Share the output file with your **networking team**
2. They will deploy **Phase 2** (private endpoints and DNS configuration)
3. Once Phase 2 is complete, these resources will be accessible via private network only

## Next Steps

### For You (After This Deployment)
1. ✅ Save the Terraform outputs
2. ✅ Share Phase 1 outputs with the networking team
3. ⏸️ Wait for networking team to complete Phase 2
4. ➡️ Proceed to Phase 3 (AI Foundry deployment)

### For Networking Team (Phase 2)
The networking team needs to create:
- Private Endpoint for Storage (blob)
- Private Endpoint for Cosmos DB (sql)
- Private Endpoint for AI Search
- Private DNS Zone configurations
- VNet/Subnet configurations

Required inputs from Phase 1:
- `storage_account_id`
- `cosmosdb_account_id`
- `ai_search_id`
- `resource_group_name`
- `location`
- `environment` (dev/prod) - **CRITICAL for Phase 3**
- `department` - **CRITICAL for Phase 3**
- `instance_number` - **CRITICAL for Phase 3**

## Cleanup (If Needed)

To remove all resources created in Phase 1:

```bash
terraform destroy
```

**Warning**: This will permanently delete:
- All stored data in Cosmos DB
- All files in Storage Account
- All search indexes in AI Search

## Troubleshooting

### Authentication Issues
```bash
# Re-authenticate
az login --scope https://management.azure.com/.default

# Verify subscription
az account show
```

### Resource Names Already Exist
The random suffix ensures unique names. If you get naming conflicts:
1. Destroy existing resources: `terraform destroy`
2. Re-apply: `terraform apply` (generates new random suffix)

### Permission Errors
Ensure your account has these roles on the subscription:
- `Contributor` (to create resources)
- `User Access Administrator` (if assigning roles, not needed in Phase 1)

## Cost Estimation

Approximate monthly costs (US region, Standard tier):
- Storage Account: ~$25-50/month (depending on usage)
- Cosmos DB: ~$25/month (serverless) or ~$140/month (provisioned 400 RU/s)
- AI Search Standard: ~$250/month

**Total**: ~$300-400/month for this phase

## Files in This Directory

- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `providers.tf` - Azure provider configuration
- `versions.tf` - Terraform and provider version constraints
- `outputs.tf` - Output values for next phases
- `example.tfvars` - Example configuration values
- `README.md` - This file

## Support

For issues specific to:
- **Terraform configuration**: Check Terraform documentation
- **Azure resources**: Review Azure AI Foundry documentation
- **Networking**: Coordinate with your networking team
