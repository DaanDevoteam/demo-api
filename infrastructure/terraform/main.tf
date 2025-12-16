# Data source: Reference existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Application Insights for structured logging and monitoring
resource "azurerm_application_insights" "main" {
  name                = "${var.app_name}-insights"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  application_type    = "web"
  
  # Free tier: 5GB/month included
  daily_data_cap_in_gb = 1
  
  tags = var.tags
}

# App Service Plan (Linux F1 tier - Free)
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  os_type  = "Linux"
  sku_name = "F1"
  
  tags = var.tags
}

# Linux Web App (Python 3.11)
resource "azurerm_linux_web_app" "main" {
  name                = var.app_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  
  site_config {
    always_on = false  # Required for Free tier (F1)
    
    application_stack {
      python_version = "3.11"
    }
    
    app_command_line = "uvicorn app:app --host 0.0.0.0 --port 8000"
  }
  
  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT"         = "true"
    "WEBSITES_PORT"                          = "8000"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"  = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }
  
  logs {
    application_logs {
      file_system_level = "Information"
    }
    
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
  
  tags = var.tags
}