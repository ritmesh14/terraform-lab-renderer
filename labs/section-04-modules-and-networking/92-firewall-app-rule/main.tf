# Lab 92 — Azure Firewall application (L7/FQDN) rules.
#  - Build a firewall + AzureFirewallSubnet + public IP.
#  - application_rule_collection (action = Allow): the workload subnet (10.32.1.0/24)
#    may reach *.ubuntu.com and github.com over HTTP/HTTPS only. Other internet is
#    denied → controlled egress by FQDN.
resource "azurerm_resource_group" "this" {
  name     = "rg-fw-app"
  location = "eastus"
}

# The hub VNet hosting the firewall.
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-fw-app"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.32.0.0/16"]
}

# Azure Firewall must live in a subnet named exactly AzureFirewallSubnet (min /26).
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.32.0.0/26"]
}

# The firewall's public IP (SNAT egress from the workload appears to come from here).
resource "azurerm_public_ip" "fw" {
  name                = "pip-fw-app"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The Azure Firewall. AZFW_VNet = deployed in this VNet; Standard tier
# (application/FQDN rules need Standard, not Basic).
resource "azurerm_firewall" "this" {
  name                = "fw-app1-app"
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
# nested blocks inside azurerm_firewall). The collection references the
# firewall above by id.
resource "azurerm_firewall_application_rule_collection" "app-allow" {
  name                = "app-allow"
  action              = "Allow"
  priority            = 100
  resource_group_name = azurerm_resource_group.this.name
  azure_firewall_name = azurerm_firewall.this.name

  # L7 rules declare one or more protocol blocks; HTTP/HTTPS ports are implicit.
  rule {
    name             = "allow-updates"
    source_addresses = ["10.32.1.0/24"]
    protocol {
      type = "Http"
      port = 80
    }
    protocol {
      type = "Https"
      port = 443
    }
    target_fqdns = ["*.ubuntu.com", "github.com", "*.githubusercontent.com"]
  }
}

# The firewall's public IP (the SNAT address the workload's egress appears to use).
output "fw_public_ip" { value = azurerm_public_ip.fw.ip_address }
