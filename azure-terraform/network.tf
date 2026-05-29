# ============================================================
# Virtual Network
# ============================================================

# Private network that isolates all Azure resources from the internet
# by default. All VMs, NICs, and subnets live inside this VNet.
# Address space 10.0.0.0/16 provides 65,536 IP addresses.
resource "azurerm_virtual_network" "vnet" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# ============================================================
# Subnet
# ============================================================

# Logical subdivision of the VNet where VMs are placed.
# Address prefix 10.0.2.0/24 provides 256 IP addresses (10.0.2.0–10.0.2.255).
# Azure reserves 5 addresses per subnet, leaving 251 usable.
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ============================================================
# Public IPs
# ============================================================

# One static public IP per VM, allowing external access (SSH, HTTP, HTTPS).
# Static allocation ensures the IP does not change when the VM is stopped.
# Standard SKU is required — Azure is phasing out Basic SKU public IPs.
# count ties the number of public IPs to var.vm_count.
resource "azurerm_public_ip" "pip" {
  count               = var.vm_count
  name                = "pip-vm${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Static keeps the same IP across VM restarts.
  # Dynamic would reassign a different IP each time.
  allocation_method = "Static"

  # Standard SKU required for zone-redundancy and static allocation.
  # Basic SKU is deprecated and unavailable in some subscriptions.
  sku = "Standard"
}

# ============================================================
# Network Interfaces (NICs)
# ============================================================

# One NIC per VM — acts as the virtual network card connecting
# the VM to the subnet and attaching its public IP.
# count ties the number of NICs to var.vm_count.
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "vm-nic${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "internal"

    # Places the NIC inside the subnet defined above.
    subnet_id = azurerm_subnet.subnet.id

    # Azure assigns a private IP automatically from the subnet range (10.0.2.x).
    # Use "Static" here if you need predictable internal IPs.
    private_ip_address_allocation = "Dynamic"

    # Attaches the corresponding public IP to this NIC.
    # count.index ensures vm-nic1 gets pip-vm1, vm-nic2 gets pip-vm2, etc.
    public_ip_address_id = azurerm_public_ip.pip[count.index].id
  }
}
