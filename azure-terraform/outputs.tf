# ============================================================
# Outputs
# ============================================================
# Values displayed after terraform apply completes.
# Use these to configure downstream tools:
#   - vm_public_ips → update hosts.yaml in Ansible inventory
#   - vm_private_ips → inter-VM communication reference
#   - resource_group_name → used by az CLI commands
#   - nsg_id → reference in other Terraform modules if needed

# Names of all VMs created — useful to verify naming convention.
output "vm_names" {
  description = "Names of the created VMs"
  value       = azurerm_linux_virtual_machine.vm[*].name
}

# Public IPs assigned to each VM.
# Copy these into azure-ansible/educhat/inventories/home/hosts.yaml
# after each terraform apply — IPs are static but change if you
# destroy and recreate the public IP resources.
output "vm_public_ips" {
  description = "Public IP addresses of the VMs — copy into Ansible inventory after each apply"
  value       = azurerm_public_ip.pip[*].ip_address
}

# Private IPs assigned by Azure within the subnet (10.0.2.x range).
# Used for K3s master-worker communication over the private network.
output "vm_private_ips" {
  description = "Private IP addresses of the VMs (internal Azure network)"
  value       = azurerm_network_interface.nic[*].private_ip_address
}

# Resource Group name — useful for az CLI commands such as:
#   az vm list --resource-group <resource_group_name>
output "resource_group_name" {
  description = "Name of the Resource Group containing all project resources"
  value       = azurerm_resource_group.rg.name
}

# NSG ID — useful if you extend this infrastructure with additional
# Terraform modules that need to reference the existing firewall.
output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.nsg.id
}
