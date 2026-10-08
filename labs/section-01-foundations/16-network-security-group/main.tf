# ---------------------------------------------------------------------------
# Lab 16 — Network Security Group
# Builds: resource group "rg-nsg-foundation", VNet "vnet-nsg", subnet "snet-web",
# NSG "nsg-web" (RDP + HTTPS allow rules) attached to the subnet.
# Teaches: NSG security rules, rule priority, and subnet↔NSG association.
# ---------------------------------------------------------------------------

locals {
  rg = "rg-nsg-foundation"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# The VNet + subnet the NSG will protect.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.110.0.0/16"]
}

# The subnet the NSG will be attached to below.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.110.1.0/24"]
}

# A Network Security Group is a stateful firewall attached to a subnet or NIC.
# Rules are evaluated by priority (lower number = higher priority). Default
# behavior denies inbound; we add Allow rules for the ports we need.
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 200 # evaluated before higher numbers
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"    # any source port
    destination_port_range     = "3389" # RDP
    source_address_prefix      = "*"    # any source IP (tighten in prod!)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the subnet so its rules protect that subnet.
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}
