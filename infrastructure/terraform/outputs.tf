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