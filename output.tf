output "resource_group_name" {
  description = "The name of the Resource Group."
  value       = azurerm_resource_group.rg.name
}

output "vm_public_ip" {
  description = "Public IP Address of the monitored VM (Use to test SSH failure detection)."
  value       = azurerm_public_ip.pip.ip_address
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.law.id
}

output "log_analytics_portal_uri" {
  description = "Direct URI to the Log Analytics Workspace in Azure Portal."
  value       = "https://portal.azure.com/#resource${azurerm_log_analytics_workspace.law.id}/overview"
}
