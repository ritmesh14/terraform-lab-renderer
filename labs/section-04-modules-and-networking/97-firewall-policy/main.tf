# Lab 97 — Azure Firewall with a Firewall Policy (the modern pattern).
# Instead of rules attached to the firewall, rules live in a POLICY:
#  - azurerm_firewall_policy (sku Standard).
#  - azurerm_firewall_policy_rule_collection_group holding:
#      * a nat_rule_collection (DNAT SSH to the workload),
#      * a network_rule_collection (allow outbound NTP/UDP),
#      * an application_rule_collection (allow FQDNs for the workload subnet).
#  - the firewall references the policy with firewall_policy_id. Policies are
#    versioned and reusable across many firewalls.

# Terraform block: which Terraform CLI and provider versions this lab requires.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# Provider block: configures azurerm against the subscription from `az login`.
# `features {}` is an empty settings block the azurerm provider requires.
provider "azurerm" {
  features {}
}

# Resource group everything in this lab goes into.
resource "azurerm_resource_group" "this" {
  name     = "rg-fw-policy"
  location = "eastus"
}

# Hub VNet holding the firewall and the workload subnet.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-fw-policy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["172.26.0.0/20"]
}

# Azure Firewall must live in a subnet named exactly AzureFirewallSubnet (min /26).
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.26.0.0/26"]
}

# Subnet whose traffic the firewall rules target (DNAT to / egress from).
resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["172.26.0.64/26"]
}

# The firewall's public IP (the DNAT rule listens on it).
resource "azurerm_public_ip" "fw" {
  name                = "pip-fw-policy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The policy holds the rules (decoupled from the firewall resource).
resource "azurerm_firewall_policy" "this" {
  name                = "fw-policy-app1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Standard"
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  name               = "rcg-app1"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  nat_rule_collection {
    name     = "nat-ssh"
    priority = 200
    action   = "Dnat"
    rule {
      name                = "ssh-to-workload"
      source_addresses    = ["*"]
      destination_ports   = ["22"]
      destination_address = azurerm_public_ip.fw.ip_address
      translated_address  = var.workload_private_ip
      translated_port     = "22"
      protocols           = ["TCP"]
    }
  }

  network_rule_collection {
    name     = "net-allow"
    priority = 300
    action   = "Allow"
    rule {
      name                  = "allow-to-time"
      source_addresses      = ["172.26.0.64/26"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
      protocols             = ["UDP"]
    }
  }

  application_rule_collection {
    name     = "app-allow"
    priority = 400
    action   = "Allow"
    # In firewall-policy rule groups, protocols is a nested block (one entry
    # per protocol, with an optional port) and the FQDNs use destination_fqdns.
    rule {
      name             = "allow-updates"
      source_addresses = ["172.26.0.64/26"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.ubuntu.com", "github.com"]
    }
  }
}

# The firewall references the policy — no rules on the firewall itself.
resource "azurerm_firewall" "this" {
  name                = "fw-app1-hub"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.this.id

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}

# The public IP for DNAT/SSH tests and the policy id (policies can be shared).
output "firewall_public_ip" { value = azurerm_public_ip.fw.ip_address }
output "policy_id" { value = azurerm_firewall_policy.this.id }
