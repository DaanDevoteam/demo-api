# Output the App Service URL
output "app_service_url" {
  description = "URL of the deployed App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

# Output the App Service name
output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

# Output the App Service Plan name
output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

# Output the resource group name
output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

# Output App Service default hostname
output "default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.main.default_hostname
}
# Output Application Insights name
output "application_insights_name" {
  description = "Name of the Application Insights resource"
  value       = azurerm_application_insights.main.name
}

# Output Application Insights instrumentation key (for reference)
output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

# Output Alert Rule name
output "alert_rule_name" {
  description = "Name of the log alert rule"
  value       = azurerm_monitor_scheduled_query_rules_alert_v2.high_error_rate.name
}

# Output Action Group name
output "action_group_name" {
  description = "Name of the action group for Google Chat"
  value       = azurerm_monitor_action_group.google_chat.name
}

# Output Logic App name
output "logic_app_name" {
  description = "Name of the Logic App for alert transformation"
  value       = azurerm_logic_app_workflow.alert_transformer.name
}

# Output Logic App callback URL
output "logic_app_callback_url" {
  description = "Callback URL for the Logic App HTTP trigger"
  value       = azurerm_logic_app_trigger_http_request.alert_trigger.callback_url
  sensitive   = true
}
