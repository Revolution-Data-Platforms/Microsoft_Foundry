# Variables for Phase 3 - AI Foundry Deployment
# This phase deploys: AI Foundry Account, Project, Connections, RBAC, Capability Host
# Requires Phase 1 (Data Stores) and Phase 2 (Networking) to be complete

# Azure subscription configuration
variable "resource_group_name_resources" {
  description = "The name of the existing resource group where resources are deployed"
  type        = string
}

variable "subscription_id_resources" {
  description = "The subscription id where the resources are deployed"
  type        = string
}

variable "location" {
  description = "The Azure region where resources are deployed"
  type        = string
}

# Naming convention variables - MUST match Phase 1
variable "environment" {
  description = "The environment for deployment (dev or prod) - MUST match Phase 1"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "department" {
  description = "The department or project name - MUST match Phase 1"
  type        = string
  validation {
    condition     = length(var.department) <= 10 && can(regex("^[a-z0-9]+$", var.department))
    error_message = "Department must be lowercase alphanumeric only, max 10 characters."
  }
}

variable "instance_number" {
  description = "The instance number for the resources - MUST match Phase 1"
  type        = string
  default     = "01"
  validation {
    condition     = can(regex("^[0-9]{2}$", var.instance_number))
    error_message = "Instance number must be exactly 2 digits (e.g., '01', '02')."
  }
}

# Network configuration - from Phase 2
variable "subnet_id_agent" {
  description = "The resource id of the subnet that has been delegated to Microsoft.App/environments"
  type        = string
}

# Model deployment configuration
variable "gpt_model_name" {
  description = "The GPT model name to deploy"
  type        = string
  default     = "gpt-4o"
}

variable "gpt_model_version" {
  description = "The GPT model version to deploy"
  type        = string
  default     = "2024-11-20"
}

variable "gpt_model_capacity" {
  description = "The capacity (TPM) for the GPT model deployment"
  type        = number
  default     = 1
}
