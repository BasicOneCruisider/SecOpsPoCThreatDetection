variable "project_name" {
  description = "Project name prefix for resources."
  type        = string
  default     = "secops-poc"
}

variable "location" {
  description = "Azure region for deployment."
  type        = string
  default     = "westeurope"
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
