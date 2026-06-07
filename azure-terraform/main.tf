resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

# ============================================================
# Resource Group
# ============================================================

# Top-level container for all resources in this project.
# Every Azure resource must belong to a resource group.
# Deleting this resource group destroys all resources inside it.
resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.resource_group_location
}