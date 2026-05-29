# ============================================================
# Network Security Group (NSG)
# ============================================================

# Acts as a firewall for the VMs. Rules are evaluated in priority order —
# lower number = higher priority. All traffic not explicitly allowed is denied.
# This NSG allows only the three ports required by EduChat:
#   - 22  → SSH (Ansible provisioning + admin access)
#   - 80  → HTTP (Traefik Ingress, redirects to app)
#   - 443 → HTTPS (future TLS termination)
#
# WARNING: source_address_prefix = "*" allows any IP.
# In production, restrict port 22 to your own IP to reduce attack surface.
resource "azurerm_network_security_group" "nsg" {
  name                = "vm-${var.environment}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Rule 1 — Allow inbound HTTP traffic on port 80.
  # Traefik Ingress listens here and routes to the EduChat frontend.
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Rule 2 — Allow inbound HTTPS traffic on port 443.
  # Reserved for future TLS termination via cert-manager or external certs.
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Rule 3 — Allow inbound SSH traffic on port 22.
  # Required for Ansible to connect and for direct admin access.
  # Consider restricting source_address_prefix to your IP in production.
  security_rule {
    name                       = "AllowSSH"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

# ============================================================
# NSG Association
# ============================================================

# CRITICAL: an NSG does nothing until it is explicitly associated
# with a network interface. This resource applies the NSG rules
# to every NIC created above (one association per VM).
# Without this, the NSG exists but all traffic flows unrestricted.
resource "azurerm_network_interface_security_group_association" "nisga" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
