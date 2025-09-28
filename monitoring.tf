# ----------------------------------------------------
# 1. Log Analytics Agent Installation (Data Ingestion)
#    (Nécessite azurerm_linux_virtual_machine.vm et azurerm_log_analytics_workspace.law)
# ----------------------------------------------------

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

  depends_on = [
    azurerm_linux_virtual_machine.vm,
  ]
}

# ----------------------------------------------------
# 2. Azure Monitor Alert Rule (Détection de Tentatives SSH Échouées)
# ----------------------------------------------------

# Utilisation de la ressource supportée par votre fournisseur
resource "azurerm_monitor_scheduled_query_rules_alert" "failed_login_alert" {
  name                = "Alert-FailedSSHLoginAttempts"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # ID de la source de données (Log Analytics Workspace)
  data_source_id = azurerm_log_analytics_workspace.law.id

  description = "Alerts on potential brute force attack (more than 3 failed SSH attempts in 5 minutes)."
  enabled     = true
  severity    = 2 # Warning (1=Error, 2=Warning, etc.)

  # Requête KQL simplifiée pour retourner le COUNT
  query       = <<-QUERY
    Syslog
    | where Process == "sshd"
    | where SyslogMessage contains "Failed password for"
    | summarize count()
  QUERY

  # Périodes d'évaluation (Utilisation des noms d'arguments requis par cette ressource)
  frequency   = 5   # Fréquence d'exécution de la requête en minutes (correspond à "PT5M")
  time_window = 5   # Période de temps des données analysées en minutes (correspond à "PT5M")

  # Bloc 'trigger' (Requis à la racine de la ressource)
  trigger {
    operator  = "GreaterThan"
    threshold = 3
  }

  # Définition de la notification (Action Group)
  action {
    # L'argument requis pour référencer un Action Group
    action_group = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/microsoft.insights/actionGroups/placeholder-action-group"]

    # Arguments optionnels de l'exemple de la doc pour éviter les erreurs de syntaxe
    email_subject        = "Alerte Terraform: Tentatives SSH échouées"
    custom_webhook_payload = "{}"
  }
}

# Data source pour récupérer l'ID de la souscription (utilisée dans l'Action Group ID)
data "azurerm_client_config" "current" {}
