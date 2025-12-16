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
  
  # Ignore workspace_id changes (can't be removed once set)
  lifecycle {
    ignore_changes = [workspace_id]
  }
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
  
  # Ignore hidden tags added by Azure
  lifecycle {
    ignore_changes = [tags["hidden-link: /app-insights-resource-id"]]
  }
}

# Logic App - Transforms Azure Alert payload to Google Chat format
resource "azurerm_logic_app_workflow" "alert_transformer" {
  name                = "alert-to-gchat-transformer"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

# HTTP Trigger for the Logic App
resource "azurerm_logic_app_trigger_http_request" "alert_trigger" {
  name         = "When_Azure_Alert_fires"
  logic_app_id = azurerm_logic_app_workflow.alert_transformer.id
  
  schema = jsonencode({
    type = "object"
    properties = {
      schemaId = { type = "string" }
      data = {
        type = "object"
        properties = {
          essentials = {
            type = "object"
            properties = {
              alertRule       = { type = "string" }
              severity        = { type = "string" }
              monitorCondition = { type = "string" }
              firedDateTime   = { type = "string" }
              description     = { type = "string" }
            }
          }
        }
      }
    }
  })
}

# Compose the Google Chat message
resource "azurerm_logic_app_action_custom" "compose_message" {
  name         = "Compose_Google_Chat_Message"
  logic_app_id = azurerm_logic_app_workflow.alert_transformer.id
  
  body = <<-JSON
    {
      "type": "Compose",
      "inputs": {
        "text": "@{concat('@Sir Fix-a-lot Alert: ', triggerBody()?['data']?['essentials']?['alertRule'], ' fired at ', convertTimeZone(triggerBody()?['data']?['essentials']?['firedDateTime'], 'UTC', 'W. Europe Standard Time', 'HH:mm'))}"
      },
      "runAfter": {}
    }
  JSON
}

# HTTP POST to Google Chat webhook
resource "azurerm_logic_app_action_custom" "post_to_gchat" {
  name         = "Post_to_Google_Chat"
  logic_app_id = azurerm_logic_app_workflow.alert_transformer.id
  
  body = <<-JSON
    {
      "type": "Http",
      "inputs": {
        "method": "POST",
        "uri": "${var.google_chat_webhook_url}",
        "headers": {
          "Content-Type": "application/json"
        },
        "body": "@outputs('Compose_Google_Chat_Message')"
      },
      "runAfter": {
        "Compose_Google_Chat_Message": ["Succeeded"]
      }
    }
  JSON
}

# Action Group - Sends alerts to Logic App for transformation
resource "azurerm_monitor_action_group" "google_chat" {
  name                = "google-chat-incidents"
  resource_group_name = data.azurerm_resource_group.main.name
  short_name          = "gchat-alert"
  
  logic_app_receiver {
    name                    = "alert-transformer"
    resource_id             = azurerm_logic_app_workflow.alert_transformer.id
    callback_url            = azurerm_logic_app_trigger_http_request.alert_trigger.callback_url
    use_common_alert_schema = true
  }
  
  tags = var.tags
}

# Alert Rule - Triggers when error traces >= 2 in 5 minutes
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_error_rate" {
  name                = "high-error-rate-alert"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  description         = "Alert when error count exceeds threshold"
  severity            = 2
  
  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  scopes               = [azurerm_application_insights.main.id]
  
  criteria {
    query = <<-QUERY
      traces
      | where severityLevel >= 3
    QUERY
    
    time_aggregation_method = "Count"
    operator                = "GreaterThanOrEqual"
    threshold               = 2
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  
  action {
    action_groups = [azurerm_monitor_action_group.google_chat.id]
  }
  
  tags = var.tags
}