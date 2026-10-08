# Lab 89 — deploy an Azure Firewall.
#  - rg-fw-deploy, vnet-hub-fw-deploy (10.29.0.0/16), AzureFirewallSubnet (10.29.0.0/26).
#  - a public IP for the firewall's frontend.
#  - azurerm_firewall with sku AZFW_VNet/Standard. The firewall's private IP comes
#    from the AzureFirewallSubnet; lab 90 routes workload traffic to it.
# Output: the firewall's private IP (used by the route table in lab 90).

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-fw-deploy"
  location = "eastus"
}

# The hub VNet that hosts the firewall.
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-fw-deploy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.29.0.0/16"]
}

# Azure Firewall MUST live in a subnet named exactly AzureFirewallSubnet
# (min /26, shared with nothing else) — this name is the requirement.
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.29.0.0/26"]
}

# The firewall's public IP (inbound traffic and SNAT'd egress use it).
resource "azurerm_public_ip" "fw" {
  name                = "pip-fw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The Azure Firewall: a managed stateful firewall. AZFW_VNet = deployed in this
# VNet; Standard tier = NAT + network + application (FQDN) rules. No rules yet —
# labs 90-92 add routing and rules.
resource "azurerm_firewall" "this" {
  name                = "fw-app1-hub"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  # Each ip_configuration pairs one AzureFirewallSubnet with one public IP and
  # hands the firewall its private IP (read in the outputs below).
  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}

# This private IP is the next hop the route table in lab 90 points at.
output "firewall_private_ip" { value = azurerm_firewall.this.ip_configuration[0].private_ip_address }
output "firewall_id" { value = azurerm_firewall.this.id }
