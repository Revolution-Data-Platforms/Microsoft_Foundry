# Federal Government Naming Convention

## Overview

This configuration implements a standardized naming convention for federal government deployments with environment-based prefixes and structured resource names.

## Naming Pattern

### Environment Prefix Mapping

| Environment | Prefix | Full Name |
|-------------|--------|-----------|
| `dev` | `scned` | Secure Cloud Network Engineering Development |
| `prod` | `scped` | Secure Cloud Platform Engineering Production |

### Resource Naming Format

**Standard resources** (support dashes):
```
<prefix>-<department>-<service>-<instance>
```

**Storage accounts** (no dashes allowed):
```
<prefix><department>sa<instance>
```

## Examples

### Development Environment (`environment = "dev"`)

With configuration:
```hcl
environment     = "dev"
department      = "ebida"
instance_number = "01"
```

Creates:
- **AI Search**: `scned-ebida-search-01`
- **Cosmos DB**: `scned-ebida-cosmos-01`
- **Storage Account**: `scnedebidasa01`
- **AI Foundry** (Phase 3): `scned-ebida-aifoundry-01`

### Production Environment (`environment = "prod"`)

With configuration:
```hcl
environment     = "prod"
department      = "ebida"
instance_number = "01"
```

Creates:
- **AI Search**: `scped-ebida-search-01`
- **Cosmos DB**: `scped-ebida-cosmos-01`
- **Storage Account**: `scpedebidasa01`
- **AI Foundry** (Phase 3): `scped-ebida-aifoundry-01`

## Configuration Variables

### Required Variables

| Variable | Description | Example | Validation |
|----------|-------------|---------|------------|
| `environment` | Environment type | `dev` or `prod` | Must be exactly "dev" or "prod" |
| `department` | Department/project code | `ebida` | Lowercase alphanumeric, max 10 chars |
| `instance_number` | Instance identifier | `01` | Exactly 2 digits |

### Variable Validation Rules

**Environment**:
- ✅ `dev` → Creates names with `scned` prefix
- ✅ `prod` → Creates names with `scped` prefix
- ❌ Any other value → Terraform will fail validation

**Department**:
- ✅ `ebida`, `finance`, `hr` → Valid
- ✅ `dept01`, `proj2024` → Valid (alphanumeric)
- ❌ `e-bida` → Invalid (no dashes)
- ❌ `EBIDA` → Invalid (must be lowercase)
- ❌ `departmentname` → Invalid (max 10 characters)

**Instance Number**:
- ✅ `01`, `02`, `10`, `99` → Valid
- ❌ `1` → Invalid (must be 2 digits)
- ❌ `001` → Invalid (must be exactly 2 digits)

## Storage Account Naming Rules

Azure Storage accounts have strict naming requirements:
- **Length**: 3-24 characters
- **Characters**: Lowercase letters and numbers only (no dashes, underscores, or special chars)
- **Uniqueness**: Must be globally unique across all of Azure

### Calculation

For `scnedebidasa01`:
```
scned (5) + ebida (5) + sa (2) + 01 (2) = 14 characters ✅
```

Maximum department length to stay under 24 characters:
```
24 - 5 (prefix) - 2 (sa) - 2 (instance) = 15 characters available for department
```

**However**, we recommend keeping department names to **10 characters or less** for:
- Consistency with other resource names
- Buffer for future naming needs
- Easier readability

## Multi-Instance Deployments

Deploy multiple instances by incrementing `instance_number`:

### First Instance
```hcl
instance_number = "01"
```
Creates: `scned-ebida-search-01`, `scned-ebida-cosmos-01`, `scnedebidasa01`

### Second Instance
```hcl
instance_number = "02"
```
Creates: `scned-ebida-search-02`, `scned-ebida-cosmos-02`, `scnedebidasa02`

### Third Instance
```hcl
instance_number = "03"
```
Creates: `scned-ebida-search-03`, `scned-ebida-cosmos-03`, `scnedebidasa03`

## Resource Tags

All resources are tagged with:

```hcl
tags = {
  Environment = var.environment       # "dev" or "prod"
  Department  = var.department        # e.g., "ebida"
  Instance    = var.instance_number   # e.g., "01"
  ManagedBy   = "Terraform"
  Phase       = "Phase1-DataStores"
}
```

## Outputs for Phase 3

The following naming values are exported for use in Phase 3:

| Output | Description | Example Value |
|--------|-------------|---------------|
| `environment` | Environment type | `dev` |
| `department` | Department code | `ebida` |
| `instance_number` | Instance number | `01` |
| `naming_prefix` | Combined prefix | `scned-ebida` |
| `aifoundry_name` | AI Foundry name for Phase 3 | `scned-ebida-aifoundry-01` |

**⚠️ CRITICAL**: Phase 3 MUST use the exact same values for `environment`, `department`, and `instance_number` to ensure naming consistency across all resources.

## Best Practices

1. **Use lowercase only** for department names
2. **Keep department names short** (5-8 characters recommended)
3. **Document your naming convention** in your organization's wiki/docs
4. **Use the same values** across all phases (Phase 1, 2, and 3)
5. **Reserve instance 01** for production-like workloads
6. **Use higher instance numbers** (02, 03, etc.) for testing/development variants

## Common Department Codes (Examples)

| Department | Code | Resources Example |
|------------|------|-------------------|
| E-Business Intelligence & Data Analytics | `ebida` | `scned-ebida-search-01` |
| Finance | `finance` | `scned-finance-search-01` |
| Human Resources | `hr` | `scned-hr-search-01` |
| Information Technology | `it` | `scned-it-search-01` |
| Operations | `ops` | `scned-ops-search-01` |

## Validation During Deployment

Terraform will validate your inputs before deployment:

```bash
terraform plan
```

Example validation errors:

```
Error: Invalid value for variable
│ Environment must be either 'dev' or 'prod'.

Error: Invalid value for variable
│ Department must be lowercase alphanumeric only, max 10 characters.

Error: Invalid value for variable
│ Instance number must be exactly 2 digits (e.g., '01', '02').
```

## Quick Reference

```hcl
# terraform.tfvars

# Standard dev environment
environment     = "dev"
department      = "ebida"
instance_number = "01"

# Results in:
# - scned-ebida-search-01
# - scned-ebida-cosmos-01
# - scnedebidasa01
# - scned-ebida-aifoundry-01 (Phase 3)
```

```hcl
# terraform.tfvars

# Production environment
environment     = "prod"
department      = "ebida"
instance_number = "01"

# Results in:
# - scped-ebida-search-01
# - scped-ebida-cosmos-01
# - scpedebidasa01
# - scped-ebida-aifoundry-01 (Phase 3)
```
