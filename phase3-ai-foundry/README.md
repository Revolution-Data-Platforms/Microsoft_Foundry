# Phase 3: AI Foundry Deployment

This directory contains Terraform configuration for deploying the **AI Foundry infrastructure** with complete integration to the data stores and networking from previous phases.

## What This Phase Deploys

- **Azure AI Foundry Account** (AIServices) with VNet injection
- **GPT-4o Model Deployment** (configurable model and version)
- **AI Foundry Project** with system-assigned managed identity
- **Service Connections** to Cosmos DB, Storage, and AI Search
- **RBAC Role Assignments** for project identity
- **Project Capability Host** (Agents)
- **Cosmos DB SQL Role Assignments** for data plane access

## Architecture

```
Phase 3 (Final Deployment)
┌──────────────────────────────────────────────────────────┐
│ AI Foundry Account (scned-ebida-aifoundry-01)           │
│  ├─ System Managed Identity                             │
│  ├─ GPT-4o Deployment                                    │
│  ├─ VNet Injection (Agent Subnet)                        │
│  └─ Project (scned-ebida-project-01)                     │
│     ├─ System Managed Identity                           │
│     ├─ Capability Host (Agents)                          │
│     └─ Service Connections:                              │
│        ├─ Cosmos DB (scned-ebida-cosmos-01)              │
│        ├─ Storage (scnedebidasa01)                       │
│        └─ AI Search (scned-ebida-search-01)              │
└──────────────────────────────────────────────────────────┘
                    ↓ (RBAC Permissions)
┌──────────────────────────────────────────────────────────┐
│ Phase 1 Resources (via Private Endpoints)                │
│  ├─ Cosmos DB (🔒 Private Only)                          │
│  ├─ Storage Account (🔒 Private Only)                    │
│  └─ AI Search (🔒 Private Only)                          │
└──────────────────────────────────────────────────────────┘
```

## Prerequisites

### ✅ Phase 1 Must Be Complete
- Storage Account deployed
- Cosmos DB deployed
- AI Search deployed
- All with public access **disabled**

### ✅ Phase 2 Must Be Complete
- Private Endpoints created for all Phase 1 resources
- DNS resolution working (private IPs)
- Network connectivity verified

### ✅ Network Requirements
- **Agent Subnet** must exist and be delegated to `Microsoft.App/environments`
- Subnet must have connectivity to private endpoints
- DNS must resolve to private IPs

### ✅ Naming Convention Consistency
**CRITICAL**: Use the **exact same** values for:
- `environment` (dev or prod)
- `department` (e.g., ebida)
- `instance_number` (e.g., 01)

These must match Phase 1 for Terraform to find the resources via data sources.

## Deployment Steps

### 1. Verify Phase 1 and Phase 2 Completion

```bash
# From Phase 1 directory, verify resources exist
cd ../phase1-data-stores
terraform output

# Expected outputs should show all resource IDs
```

### 2. Get Subnet ID from Networking Team

You need the **Agent Subnet** resource ID:
```
/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/snet-agent
```

Verify subnet delegation:
```bash
az network vnet subnet show \
  --ids "/subscriptions/.../subnets/snet-agent" \
  --query "delegations[0].serviceName" \
  --output tsv
```

Expected output: `Microsoft.App/environments`

### 3. Create Configuration File

```bash
cd phase3-ai-foundry
cp example.tfvars terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Azure configuration
resource_group_name_resources = "SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP"
subscription_id_resources     = "d664c605-3027-4933-8389-616fff76ecef"
location                      = "canadaeast"

# ⚠️ MUST match Phase 1 exactly
environment     = "dev"
department      = "ebida"
instance_number = "01"

# From networking team
subnet_id_agent = "/subscriptions/.../subnets/snet-agent"

# Optional: Model configuration
gpt_model_name     = "gpt-4o"
gpt_model_version  = "2024-11-20"
gpt_model_capacity = 1
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy resources (takes ~10-15 minutes)
terraform apply
```

### 5. Capture Outputs

```bash
# Save outputs
terraform output > ../phase3-outputs.txt

# View deployment summary
terraform output deployment_summary
```

## What Gets Created?

### AI Foundry Account
- **Name**: `scned-ebida-aifoundry-01`
- **Type**: AIServices (S0 SKU)
- **Custom Subdomain**: `scned-ebida-aifoundry-01`
- **Network**: Private only, VNet injection enabled
- **Auth**: Both Entra ID and API Key supported

### AI Foundry Project
- **Name**: `scned-ebida-project-01`
- **Type**: Cognitive Services Project
- **Identity**: System-assigned managed identity
- **Description**: AI Foundry project with network-secured Agent

### Model Deployment
- **Name**: `gpt-4o` (default)
- **Version**: `2024-11-20` (default)
- **SKU**: GlobalStandard
- **Capacity**: 1 TPM unit (configurable)

### Service Connections
1. **Cosmos DB Connection**
   - Target: Phase 1 Cosmos DB
   - Auth: Azure AD (Managed Identity)
   - Purpose: Thread and message storage

2. **Storage Connection**
   - Target: Phase 1 Storage Account
   - Auth: Azure AD (Managed Identity)
   - Purpose: Agent data and blob storage

3. **AI Search Connection**
   - Target: Phase 1 AI Search
   - Auth: Azure AD (Managed Identity)
   - Purpose: Vector embeddings and RAG

### RBAC Assignments

Project Managed Identity receives:
- **Cosmos DB Operator** (account level)
- **Storage Blob Data Contributor** (account level)
- **Storage Blob Data Owner** (account level)
- **Search Index Data Contributor** (search service level)
- **Search Service Contributor** (search service level)

### Cosmos DB Data Plane Roles

Project Managed Identity receives SQL role for:
- `enterprise_memory/{project-guid}-thread-message-store` collection
- `enterprise_memory/{project-guid}-system-thread-message-store` collection
- `enterprise_memory/{project-guid}-agent-entity-store` collection

These collections are created automatically by the capability host.

### Capability Host (Agents)
- **Type**: Agents
- **Vector Store**: AI Search (from Phase 1)
- **Storage**: Storage Account (from Phase 1)
- **Thread Storage**: Cosmos DB (from Phase 1)

## Deployment Timeline

| Step | Duration | Description |
|------|----------|-------------|
| AI Foundry Account | ~2-3 min | Account creation and initialization |
| GPT-4o Deployment | ~2-3 min | Model deployment |
| AI Foundry Project | ~1-2 min | Project creation |
| Identity Propagation | 10 sec | Wait for managed identity |
| Service Connections | ~1-2 min | Create 3 connections |
| RBAC Assignments | ~1 min | Assign 4 roles |
| RBAC Propagation | 60 sec | Wait for permissions |
| Capability Host | ~3-5 min | Initialize Agents capability |
| Cosmos DB SQL Roles | ~1-2 min | Assign 3 data plane roles |
| **Total** | **~12-15 min** | Complete deployment |

## Verification

### 1. Check AI Foundry Account

```bash
az cognitiveservices account show \
  --name scned-ebida-aifoundry-01 \
  --resource-group SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP \
  --query "{Name:name, State:properties.provisioningState, Endpoint:properties.endpoint}" \
  --output table
```

### 2. Check Model Deployment

```bash
az cognitiveservices account deployment show \
  --name scned-ebida-aifoundry-01 \
  --resource-group SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP \
  --deployment-name gpt-4o \
  --query "{Name:name, Model:properties.model.name, State:properties.provisioningState}" \
  --output table
```

### 3. Check AI Foundry Project

```bash
# View project via terraform output
terraform output ai_foundry_project_id
```

### 4. Verify RBAC Assignments

```bash
# Check role assignments for project identity
PROJECT_ID=$(terraform output -raw ai_foundry_project_principal_id)

az role assignment list \
  --assignee $PROJECT_ID \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output table
```

Expected roles:
- Cosmos DB Operator
- Storage Blob Data Contributor
- Storage Blob Data Owner
- Search Index Data Contributor
- Search Service Contributor

### 5. Test AI Foundry Access

Visit the Azure AI Foundry portal:
```
https://ai.azure.com
```

Navigate to your project:
- Subscription: `d664c605-3027-4933-8389-616fff76ecef`
- Resource Group: `SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP`
- Project: `scned-ebida-project-01`

Verify:
- [ ] Project is visible
- [ ] Connections show as healthy
- [ ] Model deployment is available
- [ ] Can create an agent

## Troubleshooting

### Error: "Data source not found"

**Cause**: Phase 1 resources don't exist or naming doesn't match

**Solution**:
1. Verify Phase 1 resources exist:
   ```bash
   az storage account show --name scnedebidasa01 --resource-group SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP
   az cosmosdb show --name scned-ebida-cosmos-01 --resource-group SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP
   az search service show --name scned-ebida-search-01 --resource-group SCED-NPRD-EBIDA-CAEA-AIFOUNDRY-DEV-RGP
   ```

2. Verify naming convention variables match Phase 1:
   - `environment = "dev"`
   - `department = "ebida"`
   - `instance_number = "01"`

### Error: "Subnet delegation not found"

**Cause**: Agent subnet not delegated to `Microsoft.App/environments`

**Solution**:
```bash
az network vnet subnet update \
  --ids "/subscriptions/.../subnets/snet-agent" \
  --delegations Microsoft.App/environments
```

### Error: "Private endpoint connection failed"

**Cause**: Phase 2 not complete or DNS not working

**Solution**:
1. Verify private endpoints exist and are in "Succeeded" state
2. Test DNS resolution shows private IPs
3. Test network connectivity from agent subnet

### Error: "Role assignment failed - principal not found"

**Cause**: Managed identity not fully propagated

**Solution**: Wait longer (identity propagation can take up to 5 minutes) and re-run:
```bash
terraform apply
```

### Error: "Cosmos DB collection not found"

**Cause**: Capability host hasn't created collections yet

**Solution**: This is expected during initial deployment. The collections are created automatically when:
1. Capability host is deployed
2. First agent is created

If error persists after 10 minutes, check:
- Project managed identity has Cosmos DB Operator role
- Private endpoint to Cosmos DB is working

## Cost Estimation

Approximate monthly costs (Canada East, Standard tier):

| Resource | Cost |
|----------|------|
| AI Foundry Account (S0) | ~$0/month (usage-based) |
| GPT-4o Deployment (1 TPM) | Usage-based (~$5-10 per 1M tokens) |
| VNet Injection | ~$0/month (no additional charge) |
| **Total (excluding usage)** | ~$0/month base + usage |

**Note**: This is additive to Phase 1 costs (~$300-400/month).

**Total All Phases**: ~$300-400/month + AI usage costs

## Next Steps

### ✅ Deployment Complete!

Your AI Foundry infrastructure is now ready. You can:

1. **Access AI Foundry Portal**: https://ai.azure.com
2. **Create Your First Agent**:
   - Navigate to your project
   - Go to "Agents" section
   - Create a new agent using GPT-4o
3. **Test Connections**:
   - Verify vector search works (AI Search)
   - Verify conversation storage (Cosmos DB)
   - Verify file uploads (Storage Account)
4. **Deploy Agents**:
   - Agents will deploy to the agent subnet
   - All traffic stays within private network
   - Zero public internet exposure

## Files in This Directory

- `main.tf` - AI Foundry resource definitions
- `data.tf` - Data sources for Phase 1 resources
- `variables.tf` - Input variables
- `locals.tf` - Naming convention and calculations
- `providers.tf` - Azure provider configuration
- `versions.tf` - Terraform and provider versions
- `outputs.tf` - Deployment outputs
- `example.tfvars` - Example configuration
- `README.md` - This file

## Cleanup

To remove Phase 3 resources only:

```bash
terraform destroy
```

**Warning**: This will delete:
- AI Foundry Account and all projects
- Model deployments
- RBAC assignments
- Service connections

Phase 1 and Phase 2 resources will remain intact.

## Support

- **AI Foundry Documentation**: https://learn.microsoft.com/azure/ai-studio/
- **Terraform AzAPI Provider**: https://registry.terraform.io/providers/Azure/azapi/latest/docs
- **Azure Support**: Contact your Azure administrator

---

**🎉 Congratulations!** You've successfully deployed a fully network-secured Azure AI Foundry environment with end-to-end private connectivity!
