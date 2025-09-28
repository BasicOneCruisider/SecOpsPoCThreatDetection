# 📚 Azure Security Monitoring PoC — Terraform Project
![Azure Monitoring Service](https://miro.medium.com/v2/0*Rmsv6ThTxvl8sHK7)


**Infrastructure as Code** pour déployer un Proof-of-Concept (PoC) de surveillance de sécurité (SecOps) sur Azure : VM Linux exposée (PoC), agent Log Analytics (MMA/OMS), Log Analytics Workspace, et une règle d'alerte KQL détectant les tentatives de brute-force SSH.

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0.0-blue)
![Azure](https://img.shields.io/badge/Microsoft_Azure-Cloud-0088CC)

---

## Table des matières

- [📚 Azure Security Monitoring PoC — Terraform Project](#-azure-security-monitoring-poc--terraform-project)
  - [Table des matières](#table-des-matières)
  - [Présentation](#présentation)
  - [Architecture déployée](#architecture-déployée)
  - [Composants clés](#composants-clés)
  - [Structure des fichiers Terraform](#structure-des-fichiers-terraform)
  - [Code Terraform (fichiers)](#code-terraform-fichiers)
    - [`variables.tf`](#variablestf)
  - [Prérequis techniques](#prérequis-techniques)
  - [Guide de déploiement](#guide-de-déploiement)
  - [Validation / Simulation d'attaque](#validation--simulation-dattaque)
    - [🔐 Étape 1 — Brute-force SSH simulé](#-étape-1--brute-force-ssh-simulé)
    - [🔍 Étape 2 — Vérifier les logs (KQL)](#-étape-2--vérifier-les-logs-kql)
    - [🚨 Étape 3 — Vérifier l’alerte](#-étape-3--vérifier-lalerte)
    - [🗑️ Nettoyage](#️-nettoyage)
    - [🔐 Considérations de sécurité](#-considérations-de-sécurité)
    - [📄 Licence](#-licence)
    - [🚀 Bonus : améliorations possibles](#-bonus--améliorations-possibles)

---

## Présentation

Ce repository propose un PoC minimal pour illustrer la chaîne SecOps : **IaC ➜ collecte des logs ➜ détection d'incidents**. L'exemple détecte les **tentatives de connexion SSH échouées** (seuil : > 3 échecs en 5 minutes) à l'aide d'une règle programmée en KQL dans Azure Monitor.

---

## Architecture déployée

- Resource Group
- Virtual Network + Subnet
- Public IP + Network Interface
- Network Security Group (règle SSH ouverte pour PoC)
- Linux VM (Ubuntu)
- Log Analytics Workspace
- Agents OMS/MMA (OmsAgentForLinux) installés sur la VM
- Scheduled Query Rule (KQL) pour détecter les échecs SSH

---

## Composants clés

| Composant                  | Rôle                                     |
| -------------------------- | ---------------------------------------- |
| Log Analytics Workspace    | Centralise les logs (Syslog/SSH)         |
| Linux VM                   | Source des logs / cible de la simulation |
| OmsAgentForLinux (MMA)     | Envoie les logs vers le Workspace        |
| Scheduled Query Rule (KQL) | Détecte >3 échecs SSH sur 5 min          |
| NSG (SSH ouvert)           | Permet la simulation (⚠️ PoC seulement)  |

---

## Structure des fichiers Terraform

- `variables.tf` — variables d'entrée
- `main.tf` — ressources d'infrastructure (RG, VNet, VM, NSG, IP)
- `monitoring.tf` — agent MMA + règle d'alerte KQL
- `outputs.tf` — sorties (IP publique, workspace id)

---

## Code Terraform (fichiers)

> 💡 Copiez ces fichiers `.tf` dans le dossier racine du projet.

### `variables.tf`

````hcl
variable "project_name_prefix" {
  description = "Prefix for all Azure resources."
  type        = string
  default     = "secops-poc"
}

variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
  default     = "West Europe"
}

variable "vm_admin_username" {
  description = "The username for the VM administrator account."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "The password for the VM administrator account. In a real scenario, use SSH keys and Azure Key Vault."
  type        = string
  default     = "Password1234!"
  sensitive   = true
}
````
## Prérequis techniques

- **Azure CLI** installé et authentifié (`az login`)
- **Terraform** ≥ 1.0.0
- Rôle **Contributor** sur la subscription

---

## Guide de déploiement

```bash
terraform init
terraform plan
terraform apply
terraform output vm_public_ip
```

## Validation / Simulation d'attaque

### 🔐 Étape 1 — Brute-force SSH simulé

Exécutez 4 tentatives SSH avec un mauvais mot de passe (dans une fenêtre de 5 minutes) :

```bash
ssh azureuser@<IP_PUBLIC>  # répétez avec un mauvais mot de passe 4 fois
```

### 🔍 Étape 2 — Vérifier les logs (KQL)

Ouvrez le Log Analytics Workspace et exécutez la requête suivante :

```kql
Syslog
| where Process == "sshd"
| where SyslogMessage contains "Failed password for"
| summarize AttemptCount = count() by Computer, bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

Vous devriez voir AttemptCount >= 4.

### 🚨 Étape 3 — Vérifier l’alerte

Allez dans Azure Portal → Monitor → Alerts

Recherchez l’alerte **Alert-FailedSSHLoginAttempts** (severity 2) — elle doit apparaître si le seuil a été atteint.

---

### 🗑️ Nettoyage

```bash
terraform destroy
```

### 🔐 Considérations de sécurité

- 🔒 Ne jamais exposer SSH en production (NSG autorisant Internet uniquement pour PoC)
- ✅ Utiliser des clés SSH au lieu de mots de passe
- ✅ Stocker les secrets dans Azure Key Vault
- ✅ Sécuriser les fichiers Terraform (.tf) avec un .gitignore et/ou un backend distant sécurisé

---

### 📄 Licence

MIT — libre à utiliser, modifier, redistribuer.

---

### 🚀 Bonus : améliorations possibles

- ✅ Action Group (notifications par e-mail / webhook)
- ✅ CI/CD avec GitHub Actions (terraform fmt, validate, plan)
- ✅ Diagramme d’architecture (PNG/SVG dans le repo)
- ✅ Intégration avec Azure Sentinel pour corrélation et enrichissement




