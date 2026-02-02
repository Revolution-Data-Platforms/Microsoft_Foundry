# Phased Deployment Guide

This guide explains how to deploy the Azure AI Foundry infrastructure across **3 phases** with different teams handling different responsibilities.

## Overview

The original monolithic deployment has been split into **3 independent phases** to allow parallel work and clear separation of responsibilities:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Phase 1       │───▶│   Phase 2       │───▶│   Phase 3       │
│  Data Stores    │    │  Networking     │    │  AI Foundry     │
│                 │    │                 │    │                 │
│  Your Team      │    │  Network Team   │    │  Your Team      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Phase 1: Data Stores (Deploy Now)

**Owner**: Your Team
**Directory**: `phase1-data-stores/`
**Duration**: ~10-15 minutes

### What Gets Deployed
- Azure Storage Account
- Azure Cosmos DB for NoSQL
- Azure AI Search

### Prerequisites
- Azure subscription ID
- Resource group (must exist)
- Terraform v1.10.0+
- Azure CLI authentication

### Quick Start
```bash
cd phase1-data-stores
cp example.tfvars terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply

# Save outputs for next phases
terraform output > ../phase1-outputs.txt
```

### Outputs to Share
Share `phase1-outputs.txt` with the networking team. They need:
- `storage_account_id`
- `cosmosdb_account_id`
- `ai_search_id`
- `resource_group_name`
- `location`
- `random_suffix` ⚠️ **Critical**: You must use the same suffix in Phase 3

### Network Security
🔒 Resources are deployed with **public access DISABLED** from the start.
- Resources are created but not accessible until Phase 2
- No temporary security compromise
- Zero-trust security from day one

---

## Phase 2: Network Security (Networking Team)

**Owner**: Networking Team
**Directory**: `phase2-networking/` *(to be created)*
**Duration**: ~20-30 minutes

### What Gets Deployed
- 4 Private Endpoints (Storage, Cosmos DB, AI Search, AI Foundry)
- Private DNS Zone configurations
- VNet/Subnet validations
- Network ACL updates

### Prerequisites from Phase 1
- Phase 1 outputs file (`phase1-outputs.txt`)
- Pre-existing Virtual Network
- Pre-existing subnets:
  - Agent subnet (delegated to `Microsoft.App/environments`)
  - Private endpoint subnet
- Pre-existing Private DNS Zones (in infra subscription)

### Required DNS Zones
The following Private DNS Zones must exist:
- `privatelink.blob.core.windows.net`
- `privatelink.documents.azure.com`
- `privatelink.search.windows.net`
- `privatelink.cognitiveservices.azure.com`
- `privatelink.openai.azure.com`
- `privatelink.services.ai.azure.com`

### Configuration Template
```hcl
# phase2-networking/terraform.tfvars (example)

# From Phase 1 outputs
storage_account_id = "<from phase1-outputs.txt>"
cosmosdb_account_id = "<from phase1-outputs.txt>"
ai_search_id = "<from phase1-outputs.txt>"

# Network configuration
subnet_id_private_endpoint = "/subscriptions/.../subnets/snet-svc"
subscription_id_infra = "44444444-4444-4444-4444-444444444444"
resource_group_name_dns = "mydnsrg"
```

### Outputs to Share
After Phase 2 completion, share with your team:
- `private_endpoint_storage_id`
- `private_endpoint_cosmosdb_id`
- `private_endpoint_aisearch_id`
- Network validation status

### Verification
After deployment, verify:
- [ ] Private endpoints are in "Succeeded" state
- [ ] DNS resolution points to private IPs
- [ ] Public access is disabled on all resources
- [ ] VNet can reach private endpoints

---

## Phase 3: AI Foundry Setup (After Networking)

**Owner**: Your Team
**Directory**: `phase3-ai-foundry/` *(to be created)*
**Duration**: ~15-20 minutes

### What Gets Deployed
- Azure AI Foundry Account
- GPT-4o Model Deployment
- AI Foundry Project
- Service Connections (Cosmos DB, Storage, AI Search)
- RBAC Role Assignments
- Capability Host (Agents)

### Prerequisites from Previous Phases
- Phase 1 outputs (`phase1-outputs.txt`)
- Phase 2 completion confirmation from networking team
- Network connectivity verified

### Configuration Template
```hcl
# phase3-ai-foundry/terraform.tfvars (example)

# From Phase 1 outputs - MUST use same random_suffix!
random_suffix = "1234"  # From phase1-outputs.txt
storage_account_name = "aifoundry1234storage"
cosmosdb_account_name = "aifoundry1234cosmosdb"
ai_search_name = "aifoundry1234search"

# Network configuration (from networking team)
subnet_id_agent = "/subscriptions/.../subnets/snet-agent"

# Resource configuration
resource_group_name = "myfoundryrg"
subscription_id_resources = "55555555-5555-5555-5555-555555555555"
location = "westus3"
```

### Deployment Flow
```bash
cd phase3-ai-foundry
cp example.tfvars terraform.tfvars
# Edit terraform.tfvars - IMPORTANT: Use same random_suffix from Phase 1!
terraform init
terraform apply
```

### Final Verification
After Phase 3, verify:
- [ ] AI Foundry Account is running
- [ ] GPT-4o deployment is successful
- [ ] AI Foundry Project is created
- [ ] Service connections are healthy
- [ ] RBAC roles are assigned
- [ ] Agents capability is enabled

---

## Cross-Team Coordination

### Handoff Process

#### Phase 1 → Phase 2 Handoff
**Your Team sends to Networking Team**:
1. `phase1-outputs.txt` file
2. Resource group name
3. Azure region/location
4. Confirmation that Phase 1 is complete

**Networking Team provides**:
1. Confirmation of Phase 2 deployment
2. Private endpoint validation results
3. DNS resolution confirmation
4. Go-ahead to proceed with Phase 3

#### Phase 2 → Phase 3 Handoff
**Networking Team sends to Your Team**:
1. Confirmation email/ticket
2. Network validation test results
3. Any special networking considerations

**Your Team proceeds**:
1. Use Phase 1 outputs (especially `random_suffix`)
2. Deploy Phase 3 with networking in place
3. Verify end-to-end functionality

---

## Terraform State Management

### Recommendation: Separate State Files

Each phase should have its **own Terraform state file** stored separately:

```bash
# Phase 1 state
phase1-data-stores/
  └── terraform.tfstate

# Phase 2 state (networking team)
phase2-networking/
  └── terraform.tfstate

# Phase 3 state
phase3-ai-foundry/
  └── terraform.tfstate
```

### Using Azure Storage Backend (Recommended for Production)

Each team should configure their own backend:

```hcl
# phase1-data-stores/versions.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatestore"
    container_name       = "phase1-datastore-state"
    key                  = "terraform.tfstate"
  }
}
```

**Benefits**:
- ✅ Independent deployments and updates
- ✅ No state conflicts between teams
- ✅ Each team owns their resources
- ✅ Clear audit trail per phase

---

## Rollback Strategy

### If Phase 1 Fails
```bash
cd phase1-data-stores
terraform destroy
# Fix issues, then re-apply
terraform apply
```

### If Phase 2 Fails
```bash
cd phase2-networking
terraform destroy
# Phase 1 resources remain intact
# Fix networking issues, then retry Phase 2
```

### If Phase 3 Fails
```bash
cd phase3-ai-foundry
terraform destroy
# Phase 1 and 2 resources remain intact
# Fix AI Foundry issues, then retry Phase 3
```

### Complete Cleanup (All Phases)
```bash
# Reverse order: Phase 3, then 2, then 1
cd phase3-ai-foundry && terraform destroy
cd ../phase2-networking && terraform destroy
cd ../phase1-data-stores && terraform destroy
```

---

## Timeline Estimation

| Phase | Duration | Wait Time | Total |
|-------|----------|-----------|-------|
| Phase 1 | 10-15 min | - | 15 min |
| Handoff to Networking | - | 1-2 days | - |
| Phase 2 (Networking Team) | 20-30 min | - | 30 min |
| Handoff back to You | - | 1 day | - |
| Phase 3 | 15-20 min | - | 20 min |
| **Total** | **~1 hour** | **2-3 days** | **2-3 days** |

---

## Critical Success Factors

### ⚠️ Must Use Same Random Suffix
The `random_suffix` from Phase 1 **must** be used in Phase 3. Resource names must match:
- Phase 1 creates: `aifoundry1234storage`
- Phase 3 references: `aifoundry1234storage` (same name!)

### ⚠️ Verify Network Prerequisites
Before Phase 2, networking team must verify:
- VNet and subnets exist
- Subnet delegation is configured
- Private DNS Zones exist and are linked
- NSG/firewall rules allow traffic

### ⚠️ Wait for RBAC Propagation
Phase 3 includes delays for Azure AD role assignments to propagate:
- 10 seconds after project creation
- 60 seconds after RBAC assignments
- Don't skip these delays!

---

## Troubleshooting

### Issue: "Resource name already exists"
**Cause**: Random suffix collision
**Fix**: Run `terraform destroy` in Phase 1, then `terraform apply` (generates new suffix)

### Issue: "Cannot reach private endpoint"
**Cause**: DNS or network misconfiguration in Phase 2
**Fix**: Networking team should verify:
- Private DNS Zone links to VNet
- NSG rules allow traffic
- Private endpoint is in "Succeeded" state

### Issue: "RBAC permission denied" in Phase 3
**Cause**: Insufficient permissions or propagation delay
**Fix**:
1. Wait 5 minutes for Azure AD propagation
2. Verify your account has required roles
3. Re-run `terraform apply`

---

## Support Contacts

| Phase | Issue Type | Contact |
|-------|-----------|---------|
| Phase 1 | Terraform/Azure Resources | Your Team Lead |
| Phase 2 | Networking/DNS/Endpoints | Network Team |
| Phase 3 | AI Foundry/RBAC | Your Team Lead |
| All | Azure Subscription/Permissions | Cloud Admin |

---

## Next Steps

✅ **Start Here**: Deploy Phase 1 now
📁 Directory: `phase1-data-stores/`
📖 Documentation: `phase1-data-stores/README.md`

```bash
cd phase1-data-stores
cat README.md
```
