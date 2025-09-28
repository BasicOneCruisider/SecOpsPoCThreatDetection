variable "project_name" {
  description = "Project name prefix for resources."
  type        = string
  default     = "secops-poc"
}

variable "location" {
  description = "Azure region for deployment."
  type        = string
  default     = "francecentral"
}

variable "vm_admin_username" {
  description = "Username for the VM administrator."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Password for the VM administrator (MUST be secure in production)."
  type        = string
  # NOTE: Replace this with a secure password or use Key Vault/SSH keys in production.
  default     = "P@ssw0rd123456"
}

# Fichier pour déclarer les variables

variable "arm_client_id" {
  description = "The Client ID for the Azure Service Principal"
  type        = string
  sensitive   = true # Marqué comme sensible pour ne pas l'afficher dans les logs plan/apply
}

variable "arm_client_secret" {
  description = "The Client Secret for the Azure Service Principal"
  type        = string
  sensitive   = true
}

variable "arm_tenant_id" {
  description = "The Tenant ID for the Azure Service Principal"
  type        = string
  sensitive   = true
}

variable "arm_subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
}
