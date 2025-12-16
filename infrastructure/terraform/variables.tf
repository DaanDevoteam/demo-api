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

# Google Chat Incoming Webhook URL for alerts
variable "google_chat_webhook_url" {
  description = "Google Chat incoming webhook URL for incident alerts"
  type        = string
  default     = "https://chat.googleapis.com/v1/spaces/AAQAlHOhXCA/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=gzlXWzzpTy3qN2Q8NJl00mpj5rN7aZkYTVWssAjGdis"
  sensitive   = true
}