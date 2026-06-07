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

variable "app_name" {
  description = "Describe the name of the application"
  type = string
  default = "educhat"
}
# Azure region where all resources will be deployed.
# Changing this after initial deployment requires a full
# terraform destroy + apply since most resources are region-scoped.
# Check SKU availability in the target region before changing:
#   az vm list-skus --location "West US 2" --size Standard_D2als --output table
variable "resource_group_location" {
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

variable "resource_group_name_prefix" {
  type        = string
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
  default     = "rg"
}

variable "app_service_plan_sku_name" {
  type        = string
  description = "The SKU for the plan. Possible values include: B1, B2, B3, D1, F1, I1, I2, I3, I1v2, I2v2, I3v2, I4v2, I5v2, I6v2, P1v2, P2v2, P3v2, P0v3, P1v3, P2v3, P3v3, P1mv3, P2mv3, P3mv3, P4mv3, P5mv3, S1, S2, S3, SHARED, EP1, EP2, EP3, WS1, WS2, WS3, Y1."
  default     = "S1"
  validation {
    condition     = contains(["B1", "B2", "B3", "D1", "F1", "I1", "I2", "I3", "I1v2", "I2v2", "I3v2", "I4v2", "I5v2", "I6v2", "P1v2", "P2v2", "P3v2", "P0v3", "P1v3", "P2v3", "P3v3", "P1mv3", "P2mv3", "P3mv3", "P4mv3", "P5mv3", "S1", "S2", "S3", "SHARED", "EP1", "EP2", "EP3", "WS1", "WS2", "WS3", "Y1"], var.app_service_plan_sku_name)
    error_message = "The SKU value must be one of the following: B1, B2, B3, D1, F1, I1, I2, I3, I1v2, I2v2, I3v2, I4v2, I5v2, I6v2, P1v2, P2v2, P3v2, P0v3, P1v3, P2v3, P3v3, P1mv3, P2mv3, P3mv3, P4mv3, P5mv3, S1, S2, S3, SHARED, EP1, EP2, EP3, WS1, WS2, WS3, Y1."
  }
}

variable "app_service_plan_capacity" {
  type        = number
  description = "The number of Workers (instances) to be allocated."
  default     = 1
}

variable "front_door_sku_name" {
  type        = string
  description = "The SKU for the Front Door profile. Possible values include: Standard_AzureFrontDoor, Premium_AzureFrontDoor"
  default     = "Standard_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.front_door_sku_name)
    error_message = "The SKU value must be one of the following: Standard_AzureFrontDoor, Premium_AzureFrontDoor."
  }
}