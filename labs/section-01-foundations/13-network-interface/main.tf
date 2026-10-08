# ---------------------------------------------------------------------------
# Lab 13 — Network interface
# Builds: resource group "rg-nic-foundation", VNet "vnet-nic", subnet "snet-web"
# and NIC "nic-web-01" with one dynamic private IP.
# Teaches: azurerm_network_interface + ip_configuration, and how a NIC binds a
# future VM to a subnet.
# ---------------------------------------------------------------------------

locals {
  region = "eastus"
  rg     = "rg-nic-foundation"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = local.region
}

# The VNet + subnet the NIC will live in.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.90.0.0/16"]
}

# A VM needs a Network Interface (NIC). The NIC lives in a subnet.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.90.1.0/24"]
}

# A NIC can have several ip_configuration blocks. This one is simple:
# private IP assigned dynamically from the subnet. A NIC could also have a
# public IP, multiple IPs, etc. (see later labs).
resource "azurerm_network_interface" "web" {
  name                = "nic-web-01"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig-web"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic" # Azure picks a free private IP
  }
}

# The NIC's id is what a VM (lab 17) will reference; the private IP shows which
# address Azure picked from the subnet's 10.90.1.0/24 range.
output "nic_id" { value = azurerm_network_interface.web.id }
# The private IP Azure assigned from the subnet's range (computed, not chosen).
output "nic_private_ip" { value = azurerm_network_interface.web.private_ip_address }
