# Azure subscription ID
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "41e50375-b926-4bc4-9045-348f359cf721"
}

# Resource group (using existing one)
variable "resource_group_name" {
  description = "Existing resource group name"
  type        = string
  default     = "daan_van_der_veen-rg"
}

# Location for resources
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

# App Service name (must be globally unique)
variable "app_name" {
  description = "Name for the App Service (must be globally unique)"
  type        = string
  default     = "demo-api-daan"
}

# App Service Plan name
variable "app_service_plan_name" {
  description = "Name for the App Service Plan"
  type        = string
  default     = "demo-api-plan-tf"
}

# Common tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "demo-api"
    Purpose = "incident-agent-testing"
    Pillar  = "I Tech"
    Role    = "Futures"
    Usage   = "Training / Certification related activities"
  }
}