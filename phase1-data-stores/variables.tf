# Variables for Phase 1 - Data Stores Deployment
# This phase only deploys: Storage Account, Cosmos DB, AI Search
# All resources are deployed with public network access DISABLED

variable "resource_group_name_resources" {
  description = "The name of the existing resource group to deploy the resources into"
  type        = string
}

variable "subscription_id_resources" {
  description = "The subscription id where the resources will be deployed"
  type        = string
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

# Naming convention variables for federal government deployment
variable "environment" {
  description = "The environment for deployment (dev or prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "department" {
  description = "The department or project name (e.g., 'ebida')"
  type        = string
  validation {
    condition     = length(var.department) <= 10 && can(regex("^[a-z0-9]+$", var.department))
    error_message = "Department must be lowercase alphanumeric only, max 10 characters."
  }
}

variable "instance_number" {
  description = "The instance number for the resources (e.g., '01', '02')"
  type        = string
  default     = "01"
  validation {
    condition     = can(regex("^[0-9]{2}$", var.instance_number))
    error_message = "Instance number must be exactly 2 digits (e.g., '01', '02')."
  }
}
