# ============================================================
# Virtual Machines
# ============================================================

# Creates var.vm_count identical Linux VMs.
# vm-dev-1 is designated as the K3s master (control-plane).
# vm-dev-2 is designated as the K3s worker (agent).
# The distinction between roles is handled by Ansible, not Terraform.
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "vm-${var.environment}-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # VM size controls CPU, RAM, and cost.
  # Standard_D2als_v7 = 2 vCPU, 8 GB RAM.
  # Must be Generation 2 compatible — see variables.tf for details.
  size           = var.vm_size
  admin_username = "adminuser"

  # Attaches the NIC created for this VM index.
  # vm-dev-1 gets nic[0], vm-dev-2 gets nic[1], etc.
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  # SSH key authentication — more secure than password-based login.
  # The public key is placed in /home/adminuser/.ssh/authorized_keys.
  # The matching private key (azure_ssh_key.pem) is used by Ansible
  # and for direct SSH access from your machine.
  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.pub_key)
  }

  # OS disk configuration.
  # Standard_LRS = Standard SSD — sufficient for dev workloads.
  # Upgrade to Premium_LRS for production I/O-intensive workloads (e.g. PostgreSQL).
  # ReadWrite caching is safe for OS disks and improves boot performance.
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu Server 22.04 LTS — Generation 2 image.
  # Generation 2 is required to match the Standard_D2als_v7 VM size.
  # Mixing Gen1 images with Gen2 VM sizes causes an immediate deployment error.
  # The "daily" offer provides the most up-to-date Ubuntu 22.04 builds from Canonical.
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy-daily"
    sku       = "22_04-daily-lts-gen2"
    version   = "latest"
  }
}
