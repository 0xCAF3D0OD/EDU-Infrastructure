# ============================================================
# Provider configuration
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Pin to a specific version to avoid unexpected breaking changes
      # on future provider releases. Upgrade intentionally via:
      #   terraform init -upgrade
      version = "=4.1.0"
    }
  }

  # Minimum Terraform CLI version required to run this configuration.
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  subscription_id = var.subscription_id

  # Disables automatic registration of Azure resource providers.
  # Required on restricted subscriptions where the service principal
  # does not have permission to register providers globally.
  # Remove only if you have Contributor access on the subscription.
  resource_provider_registrations = "none"

  features {}
}

