# NOTE: Ce fichier suppose que vous avez :
# 1. Le fichier SSHKEYSEC.pem dans le même répertoire que ce fichier.
# 2. Le port 22 ouvert sur le NSG pour l'IP source de votre machine.
# 3. L'utilisateur de la VM est configuré pour 'sudo' sans mot de passe.

# ----------------------------------------------------
# 1. Installation de l'Agent MMA/OMS (Via Remote-Exec SSH)
# ----------------------------------------------------

resource "null_resource" "install_log_analytics_agent" {
  # Déclenche la création du provisioner si la VM change
  triggers = {
    vm_id = azurerm_linux_virtual_machine.vm.id
  }

  # Dépend de la VM et du Workspace
  depends_on = [
    azurerm_linux_virtual_machine.vm,
    azurerm_log_analytics_workspace.law,
  ]

  # ⚠️ CONFIGURATION SSH : Référence à la clé privée "SSHKEYSEC.pem"
  connection {
    type        = "ssh"
    user        = azurerm_linux_virtual_machine.vm.admin_username
    host        = azurerm_public_ip.pip.ip_address

    # CORRECTION : Utilisation du nom de fichier exact
    private_key = file("id_rsa")
  }

  # Provisioner : Exécution forcée
 # ...
  # Provisioner : Exécution forcée et robuste
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo 'Démarrage de l'installation de l'agent MMA/OMS via SSH...'",

      # 1. Configuration des secrets
      "export WORKSPACE_ID='${azurerm_log_analytics_workspace.law.workspace_id}'",
      "export SHARED_KEY='${azurerm_log_analytics_workspace.law.primary_shared_key}'",

      # 2. Téléchargement et exécution du script
      # Utilisation de /bin/bash pour plus de robustesse.
      "sudo /bin/bash -c 'wget -O onboard_agent.sh https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh'",

      # Exécution directe du script via sudo /bin/bash (qui peut mieux gérer l'environnement)
      "sudo /bin/bash onboard_agent.sh -w $WORKSPACE_ID -s $SHARED_KEY -d opinsights.azure.com",

      "echo 'Installation de l'agent terminée.'",

      # Nettoyage
      "unset WORKSPACE_ID SHARED_KEY",
    ]
  }
# ...
}

# ----------------------------------------------------
# 2. Règle d'Alerte Azure Monitor
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
    threshold = 3
  }

  action {
    action_group           = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/microsoft.insights/actionGroups/placeholder-action-group"]
    email_subject          = "Alerte Terraform: Tentatives SSH échouées"
    custom_webhook_payload = "{}"
  }
}

# Data source pour récupérer l'ID de la souscription
data "azurerm_client_config" "current" {}
