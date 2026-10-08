# ---------------------------------------------------------------------------
# Lab 25 — cidrsubnet / cidrhost with for-expressions (advanced addressing)
# Builds: resource group "rg-cidrsubnet", VNet "vnet-cidrsubnet" (172.18.0.0/20)
# and four subnets (snet-web/app/data/mgmt) derived by cidrsubnet().
# Teaches: computing CIDRs programmatically instead of hard-coding them.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# The azurerm provider configures the Azure plugin. `features {}` is required
# even when empty. Credentials come from `az login` or the ARM_* env vars.
provider "azurerm" {
  features {}
}

# `locals {}` holds the base CIDR and the tier names; everything below is computed.
locals {
  rg   = "rg-cidrsubnet"
  base = "172.18.0.0/20" # /20 = 4096 addresses
  tier = ["web", "app", "data", "mgmt"]

  # cidrsubnet(PREFIX, NEWBITS, NETNUM) carves a smaller CIDR out of a larger one.
  # Here NEWBITS=6 turns /20 into /20+6 = /26. NETNUM picks which /26 slice (0,1,2,3).
  # cidrhost(CIDR, HOSTNUM) returns a specific host IP inside that CIDR.
  subnets = [
    for i, t in local.tier : {
      name  = "snet-${t}"
      cidr  = cidrsubnet(local.base, 6, i)              # e.g. 172.18.0.0/26, 172.18.0.64/26, ...
      first = cidrhost(cidrsubnet(local.base, 6, i), 1) # host .1
    }
  ]
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# The VNet whose address space is the base the subnets are carved from.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-cidrsubnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.base]
}

# Build a map keyed by name so for_each can iterate it (for_each needs a map/set).
resource "azurerm_subnet" "this" {
  for_each             = { for s in local.subnets : s.name => s }
  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.cidr]
}

# A `for` over a list of objects builds a map of name -> {cidr, first_host}.
output "subnets" {
  value = { for s in local.subnets : s.name => { cidr = s.cidr, first_host = s.first } }
}
