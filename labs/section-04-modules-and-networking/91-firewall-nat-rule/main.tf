# Lab 91 — Azure Firewall DNAT (Destination NAT).
#  - Build a firewall in AzureFirewallSubnet with a public IP.
#  - nat_rule_collection with action = Dnat: inbound port 22 on the firewall's public
#    IP → translated to the workload VM's port 22 (translated_address).
# So you SSH to the FIREWALL's public IP and land on the (private) workload VM.
variable "workload_private_ip" { type = string }

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-fw-nat"
  location = "eastus"
}

# The hub VNet hosting the firewall (and, in a full setup, the workload).
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-fw-nat"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.31.0.0/16"]
}

# Azure Firewall must live in a subnet named exactly AzureFirewallSubnet (min /26).
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.31.0.0/26"]
}

# The public IP the DNAT rule listens on (the address you SSH to).
resource "azurerm_public_ip" "fw" {
  name                = "pip-fw-nat"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The Azure Firewall. AZFW_VNet = deployed in this VNet; Standard tier.
resource "azurerm_firewall" "this" {
  name                = "fw-app1-nat"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}

# In azurerm 3.x rule collections are SEPARATE resources (they are no longer
# nested blocks inside azurerm_firewall). DNAT: port 22 on the firewall's
# public IP is forwarded to the workload VM's private IP.
resource "azurerm_firewall_nat_rule_collection" "nat-ssh" {
  name                = "nat-ssh"
  priority            = 100
  action              = "Dnat"
  resource_group_name = azurerm_resource_group.this.name
  azure_firewall_name = azurerm_firewall.this.name

  rule {
    name                  = "ssh-to-workload"
    source_addresses      = ["*"]
    destination_ports     = ["22"]
    destination_addresses = [azurerm_public_ip.fw.ip_address]
    translated_port       = "22"
    translated_address    = var.workload_private_ip
    protocols             = ["TCP"]
  }
}

# SSH here (port 22) and the DNAT rule lands you on the workload VM.
output "fw_public_ip" { value = azurerm_public_ip.fw.ip_address }
