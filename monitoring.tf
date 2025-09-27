# ----------------------------------------------------
# 1. Log Analytics Agent Installation (Data Ingestion)
# ----------------------------------------------------

# Installe l'extension de l'agent MMA (Log Analytics) sur la VM Linux.
# Ceci permet à la VM d'envoyer ses logs système (syslog, security) au Workspace.
resource "azurerm_virtual_machine_extension" "log_analytics_agent" {
  name                 = "OMSExtension"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Oms"
  type                 = "OmsAgentForLinux"
  type_handler_version = "1.14"

  settings = <<SETTINGS
    {
      "workspaceId": "${azurerm_log_analytics_workspace.law.workspace_id}"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey": "${azurerm_log_analytics_workspace.law.primary_shared_key}"
    }
PROTECTED_SETTINGS
  
  # Dépend de la VM pour être créé, garantissant l'ordre de déploiement
  depends_on = [
    azurerm_linux_virtual_machine.vm,
  ]
}

# ----------------------------------------------------
# 2. Azure Monitor Alert Rule (Basic Threat Detection - KQL)
# ----------------------------------------------------

# Simule la détection d'une attaque par force brute (trop de tentatives de connexion SSH échouées).
# NOTE: En production, on utiliserait le SecurityEvent ou Syslog table, mais 
# pour un PoC simple, on surveille les logs 'Syslog' standard.

resource "azurerm_monitor_scheduled_query_rules_alert" "failed_login_alert" {
  name                = "Alert-FailedSSHLoginAttempts"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  data_source_id = azurerm_log_analytics_workspace.law.id

  # Définition de la Requête KQL pour la détection
  criteria {
    # Requête: Compte le nombre d'erreurs d'authentification SSH 
    # (recherchant le message "Failed password for" dans les logs Syslog)
    metric_namespace = "microsoft.operationalinsights/workspaces"
    metric_name      = "Log"

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
    
    # KQL Query
    query      = <<-KQL
      Syslog 
      | where Process == "sshd" 
      | where SyslogMessage contains "Failed password for"
      | summarize count() by Computer
    KQL
    
    # Alerte si le nombre de tentatives échouées dépasse 3 sur la période de 5 minutes
    time_aggregation = "Count"
    operator         = "GreaterThan"
    threshold        = 3
    
    # Période d'évaluation (5 minutes)
    frequency      = "PT5M" 
    # Période de temps des données analysées (5 minutes)
    window_duration = "PT5M"
  }

  # Définition de la notification (Action Group - requis pour l'envoi d'emails/SMS)
  action {
    # Placeholder: En production, vous feriez référence à un azurerm_monitor_action_group réel.
    action_group_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/microsoft.insights/actiongroups/placeholder-action-group"
  }

  description     = "Alerts on potential brute force attack (more than 3 failed SSH attempts in 5 minutes)."
  enabled         = true
  severity        = 2 # Warning
}

# Data source pour récupérer l'ID de la souscription
data "azurerm_client_config" "current" {}
