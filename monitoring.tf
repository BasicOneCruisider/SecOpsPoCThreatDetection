# ----------------------------------------------------
# 1. Log Analytics Agent Installation (Data Ingestion)
# ----------------------------------------------------

# La ressource azurerm_virtual_machine_extension est correcte
resource "azurerm_virtual_machine_extension" "log_analytics_agent" {
  name                 = "OMSExtension"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Oms"
  type                 = "OmsAgentForLinux"
  type_handler_version = "1.14"

  settings = <<-SETTINGS
    {
      "workspaceId": "${azurerm_log_analytics_workspace.law.workspace_id}"
    }
  SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "workspaceKey": "${azurerm_log_analytics_workspace.law.primary_shared_key}"
    }
  PROTECTED_SETTINGS
  
  # Dépend de la VM pour être créé
  depends_on = [
    azurerm_linux_virtual_machine.vm,
  ]
}

# ----------------------------------------------------
# 2. Azure Monitor Alert Rule (Correction du Schéma d'Alerte)
# ----------------------------------------------------

# Utilisation de la ressource actuelle et non dépréciée
resource "azurerm_monitor_scheduled_query_rule" "failed_login_alert" {
  name                = "Alert-FailedSSHLoginAttempts"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  # L'ID du Workspace est défini dans le bloc 'source'
  
  # Définition des propriétés de l'alerte
  description         = "Alerts on potential brute force attack (more than 3 failed SSH attempts in 5 minutes)."
  enabled             = true
  severity            = 2 # Warning (0=Critical, 1=Error, 2=Warning, 3=Informational)

  # Définition de la fréquence et de la fenêtre de temps
  evaluation_frequency = "PT5M" # Fréquence d'exécution de la requête (5 minutes)
  window_duration      = "PT5M" # Période des données à analyser (5 minutes)
  
  # Configuration de la Requête KQL (Utilise le bloc source)
  data_source_id = azurerm_log_analytics_workspace.law.id
  
  # --- Bloc CRITERIA pour la logique de détection ---
  criteria {
    query              = <<-KQL
      Syslog 
      | where Process == "sshd" 
      | where SyslogMessage contains "Failed password for"
      | summarize AggregatedValue = count() by Computer
    KQL
    
    time_aggregation   = "Count" 
    
    # Configuration du seuil (le bloc 'metric_trigger' de l'ancienne ressource est maintenant intégré ici)
    operator           = "GreaterThan"
    threshold          = 3
    metric_measure_column = "AggregatedValue" # Doit correspondre à la colonne de votre summarize
  }

  # --- Bloc ACTIONS pour la notification ---
  action {
    # Référence à un groupe d'actions réel ou un placeholder.
    # L'argument requis ici est 'action_group_id' (dans le bloc action).
    action_group_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/microsoft.insights/actionGroups/placeholder-action-group"
  }
}

# Data source pour récupérer l'ID de la souscription
data "azurerm_client_config" "current" {}
