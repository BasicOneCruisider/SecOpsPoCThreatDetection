# NOTE: La VM, l'agent et les prérequis SSH sont supposés être gérés manuellement, pour plus de fiabilité et de controle

# ----------------------------------------------------
# 1. Configuration du Groupe d'Actions (Destination des Alertes)
# ----------------------------------------------------

resource "azurerm_monitor_action_group" "sec_alerts" {
    name                = "ag-secops-email-notifications"
    resource_group_name = azurerm_resource_group.rg.name
    location            = "Global"
    short_name          = "secopsag"

    email_receiver {
      name                    = "security_team_email"
      email_address           = "ntahimperafrancis@gmail.com"
      use_common_alert_schema = true
  }
}

# ----------------------------------------------------
# 2. Règle d'Alerte Azure Monitor (Utilise le Groupe d'Actions)
# ----------------------------------------------------

resource "azurerm_monitor_scheduled_query_rules_alert" "failed_login_alert" {
  name                = "Alert-FailedSSHLoginAttempts"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  data_source_id = azurerm_log_analytics_workspace.law.id

  description = "Alerts on potential brute force attack (more than 3 failed SSH attempts in 5 minutes)."
  enabled     = true
  severity    = 2

  query       = <<-QUERY
    Syslog
    | where Process == "sshd"
    | where SyslogMessage contains "Failed password for"
    | summarize count()
  QUERY

  frequency   = 5
  time_window = 5

  trigger {
    operator  = "GreaterThan"
    threshold = 3kalash
  }

  action {
    # Lien vers l'ID du Groupe d'Actions
    action_group           = [azurerm_monitor_action_group.sec_alerts.id]

    email_subject          = "Alerte Terraform: Tentatives SSH échouées"
    custom_webhook_payload = "{}"
  }
}

# Data source pour récupérer l'ID de la souscription
data "azurerm_client_config" "current" {}

# NOTE: Les ressources VM, VNet, etc. doivent être importées ou définies ailleurs.
