# ============================================================
# Authentication
# ============================================================

# Azure subscription ID — found in the Azure Portal under
# "Subscriptions" or via: az account show --query id
# Never hardcode this value. Always pass it via terraform.tfvars
# or an environment variable (TF_VAR_subscription_id).
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

# Azure service principal client ID (app ID).
# Required when authenticating via a service principal instead
# of interactive az login. Used for CI/CD pipelines.
variable "client_id" {
  description = "Azure service principal client ID"
  type        = string
}

# Azure service principal client secret (password).
# Treat this like a password — never commit it to git.
# Rotate regularly in production environments.
variable "client_secret" {
  description = "Azure service principal client secret"
  type        = string
}

# Azure tenant ID — the directory ID of your Azure AD tenant.
# Found in Azure Portal under "Azure Active Directory > Properties".
variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

# ============================================================
# Infrastructure
# ============================================================

# Azure region where all resources will be deployed.
# Changing this after initial deployment requires a full
# terraform destroy + apply since most resources are region-scoped.
# Check SKU availability in the target region before changing:
#   az vm list-skus --location "West US 2" --size Standard_D2als --output table
variable "location" {
  description = "Azure region where resources are deployed"
  type        = string
  default     = "West US 2"
}

# Environment label used as a prefix in all resource names
# (e.g. vm-dev-1, vm-dev-nsg). Changing this renames all resources,
# which forces a destroy + recreate on the next terraform apply.
variable "environment" {
  description = "Environment name used as a prefix for resource naming (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ============================================================
# Compute
# ============================================================

# Total number of VMs to provision. Controls the count for
# VMs, NICs, and public IPs simultaneously via the count meta-argument.
# Increasing this value adds VMs; decreasing it destroys the last ones.
variable "vm_count" {
  description = "Number of VMs to create (also controls NIC and public IP count)"
  type        = number
  default     = 2
}

# Azure VM size. Determines CPU, RAM, and cost.
# Current value: Standard_D2als_v7 = 2 vCPU, 8 GB RAM, ~$60-80/month.
# IMPORTANT: this SKU requires a Generation 2 OS image (gen2 suffix).
# Mixing a Gen2 SKU with a Gen1 image causes an immediate deployment error.
# Check available sizes in your region:
#   az vm list-skus --location "West US 2" --size Standard_D2 --output table
variable "vm_size" {
  description = "Azure VM size — must be Generation 2 compatible to match the Ubuntu 22.04 gen2 image"
  type        = string
  default     = "Standard_D2als_v7"
}

# ============================================================
# SSH access
# ============================================================

# Path to the SSH public key placed on each VM at provisioning time.
# The corresponding private key (.pem) is used by Ansible and for
# direct SSH access. Both files must exist locally before running
# terraform apply or ansible-playbook.
# WARNING: ensure the private key has restricted permissions:
#   chmod 400 ~/.ssh/azure_ssh_key.pem
variable "pub_key" {
  description = "Path to the SSH public key file used for VM authentication"
  type        = string
  default     = "~/.ssh/azure_ssh_key.pub"
}
