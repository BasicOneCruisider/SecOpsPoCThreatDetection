# 📚 Azure Security Monitoring PoC — Terraform Project (Mode Manuel)

![Azure Monitoring Service]

Infrastructure as Code pour déployer un **Proof-of-Concept (PoC)** de surveillance de sécurité (SecOps) sur Azure : VM Linux, installation **manuelle** de l'agent Log Analytics (MMA/OMS), Log Analytics Workspace, et une règle d'alerte KQL détectant les tentatives de brute-force SSH.

## Table des matières

- [Présentation](#présentation)
- [Architecture déployée](#architecture-déployée)
- [Composants clés](#composants-clés)
- [Structure des fichiers Terraform](#structure-des-fichiers-terraform)
- [Prérequis techniques](#prérequis-techniques)
- [Procédure de Déploiement Critique](#procédure-de-déploiement-critique)
  - [Étape 1 : Initialisation et Application (Infrastructure)](#étape-1--initialisation-et-application-infrastructure)
  - [Étape 2 : Installation MANUELLE de l'Agent (CRITIQUE)](#étape-2--installation-manuelle-de-lagent-critique)
- [Validation / Simulation d'attaque](#validation--simulation-dattaque)
- [Nettoyage et Sécurité](#nettoyage-et-sécurité)
  - [🗑️ Nettoyage](#️-nettoyage)
  - [🔐 Considérations de sécurité](#-considérations-de-sécurité)
- [📄 Licence](#-licence)
- [🚀 Bonus : améliorations possibles](#-bonus--améliorations-possibles)

---

## Présentation

Ce repository propose un **PoC minimal** pour illustrer la chaîne **SecOps** : IaC ➜ collecte des logs ➜ détection d'incidents. L'exemple détecte les tentatives de connexion SSH échouées (seuil : > 3 échecs en 5 minutes) à l'aide d'une règle programmée en **KQL** dans Azure Monitor.

> ⚠️ **Note sur la Méthode** : Le provisionnement automatique de l'agent via l'API Azure ayant échoué (erreurs 400/404), l'installation de l'agent **MMA/OMS** est effectuée **manuellement** via SSH après la création de la machine.

---

## Architecture déployée

- **Resource Group**
- **Virtual Network** + Subnet
- **Public IP** + Network Interface
- **Network Security Group** (règle SSH ouverte pour PoC)
- **Linux VM (Ubuntu)**
- **Log Analytics Workspace**
- **Agent MMA/OMS (OmsAgentForLinux)** : Installation manuelle requise.
- **Scheduled Query Rule (KQL)** pour détecter les échecs SSH
- **Action Group (`ag-secops-email-notifications`)** : Créé pour la notification par e-mail.

---

## Composants clés

| Composant                      | Rôle                                     | Configuration                          |
| :----------------------------- | :--------------------------------------- | :------------------------------------- |
| **Log Analytics Workspace**    | Centralise les logs (Syslog/SSH)         | Géré par Terraform                     |
| **Linux VM**                   | Source des logs / cible de la simulation | Gérée par Terraform                    |
| **Agent MMA/OMS**              | Envoie les logs vers le Workspace        | **Installation MANUELLE**              |
| **Scheduled Query Rule (KQL)** | Détecte >3 échecs SSH sur 5 min          | Créé par Terraform                     |
| **Action Group**               | Destination des notifications            | E-mail à `ntahimperafrancis@gmail.com` |

---

## Structure des fichiers Terraform

- **`main.tf`** — Fichier unique contenant toutes les ressources (Infra, Monitoring, Variables et Outputs).
- **Fichiers de secrets** (`*.tfvars` ou variables d'environnement `ARM_*`).

---

## Prérequis techniques

- **Azure CLI** installé et authentifié (`az login`).
- **Terraform ≥ 1.0.0**.
- Rôle **`Contributor`** sur la subscription.
- **Clé privée SSH** (Ex: `SSHKEYSEC.pem`) correspondant à la clé publique configurée dans `main.tf`.

---

## Procédure de Déploiement Critique

### Étape 1 : Initialisation et Application (Infrastructure)

Cette étape crée la VM, le Log Analytics Workspace, le Groupe d'Actions et la Règle d'Alerte KQL.

````bash
terraform init
terraform apply
````

### Étape 2 : Installation MANUELLE de l'Agent (CRITIQUE)

Dès que `terraform apply` est terminé (la VM est créée), vous devez vous connecter pour installer l'agent.

1.  **Récupérez les clés :**
    * **IP Publique** de la VM (`terraform output vm_public_ip`).
    * **Workspace ID** et **Shared Key** (`terraform output law_workspace_id` et `terraform output law_primary_key`).
2.  **Connexion SSH :**

```bash
ssh -i SSHKEYSEC.pem <votre_utilisateur>@<IP_PUBLIQUE_VM>
```
### Installation de l'Agent MMA/OMS :

Exécutez les commandes suivantes sur la VM (remplacez les placeholders : `<ID>` et `<CLÉ>`) :


# ⚠️ Vérifiez que l'utilisateur de la VM a la permission NOPASSWD pour sudo, sinon l'installation échouera.
# Téléchargement et préparation
```bash
wget [https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh](https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh) -O onboard_agent.sh
chmod +x onboard_agent.sh
```

# Exécution de l'installation avec les clés du Workspace

```bash
sudo /bin/bash onboard_agent.sh -w <ID> -s <CLÉ> -d opinsights.azure.com

```

> L'agent est actif immédiatement après l'exécution de cette commande.

---

## Validation / Simulation d'attaque

### 🔐 Étape 1 — Brute-force SSH simulé

Exécutez **4 tentatives SSH** avec un mauvais mot de passe (dans une fenêtre de 5 minutes) :


ssh utilisateur_incorrect@<IP_PUBLIC> # Répétez 4 fois avec un mot de passe incorrect.

### 🔍 Étape 2 — Vérification des logs (KQL)

Ouvrez le **Log Analytics Workspace** et exécutez la requête pour vérifier l'arrivée des logs :

```kql
Syslog
| where Process == "sshd"
| where SyslogMessage contains "Failed password for"
| summarize AttemptCount = count() by Computer, bin(TimeGenerated, 5m)
| order by TimeGenerated desc

```

### 🚨 Étape 3 — Vérifier l’alerte

Si `AttemptCount` atteint **4 ou plus**, l'alerte se déclenchera :

1.  Allez dans Azure Portal → Monitor → **Alerts**.
2.  Consultez votre boîte e-mail (`ntahimperafrancis@gmail.com`).

---

## Nettoyage et Sécurité

### 🗑️ Nettoyage

```bash
terraform destroy
```

### 🔐 Considérations de sécurité

* **🔒 Règle NSG** : Ne jamais exposer SSH en production (`source_address_prefix` doit être votre IP locale, non `0.0.0.0/0`).
* **✅ Agent MMA/OMS** : Cet agent est déprécié. Pour la production, migrez vers l'**Agent Azure Monitor (AMA)**.

---

## 📄 Licence

**MIT** — libre à utiliser, modifier, redistribuer.

---

## 🚀 Bonus : améliorations possibles

* ✅ Intégration avec **Azure Sentinel** pour corrélation et enrichissement.
* ✅ Utilisation d'une **Image VM Custom** pour pré-installer l'agent Log Analytics.
````
