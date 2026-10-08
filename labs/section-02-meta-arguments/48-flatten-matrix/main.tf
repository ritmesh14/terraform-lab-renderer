# Lab 48 — flatten(): nested structures → one flat list.
# A matrix of region × tier is a list-of-lists. flatten() removes the nesting so
# for_each can iterate it. One subnet per (region, tier) pair is created.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}
# The azurerm provider is the bridge to Azure; it must be configured (features {}
# is the minimal required argument) before any azurerm_* resource can be planned.
provider "azurerm" {
  features {}
}

# Inputs: the two axes of the matrix. Every combination of these lists becomes
# one subnet — add an entry and re-apply to fan out another row/column.
variable "regions" {
  type    = list(string)
  default = ["regionA", "regionB"]
}
# The second axis of the matrix (tiers are the subnets inside each region's VNet).
variable "tiers" {
  type    = list(string)
  default = ["web", "app"]
}
# locals: per-region CIDRs, the nested matrix, and its flattened form. The
# whole matrix is computed before any resource is created.
locals {
  rg = "rg-flatten"
  region_cidr = {
    regionA = "172.20.0.0/20"
    regionB = "172.21.0.0/20"
  }

  # NESTED: for each region, a list of {region, tier, cidr}. This is a list of lists.
  nested = [
    for r in var.regions : [
      for i, t in var.tiers : {
        region = r
        tier   = t
        cidr   = cidrsubnet(local.region_cidr[r], 6, i) # /26 carved from the region CIDR
      }
    ]
  ]
  # flatten() turns the list-of-lists into ONE flat list for for_each.
  flat = flatten(local.nested)
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# One VNet per region (for_each over a set of regions).
resource "azurerm_virtual_network" "this" {
  for_each            = toset(var.regions)
  name                = "vnet-${each.key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.region_cidr[each.key]]
}

# One subnet per (region, tier). We build a map keyed by "region-tier" for for_each.
resource "azurerm_subnet" "this" {
  for_each             = { for s in local.flat : "${s.region}-${s.tier}" => s }
  name                 = "snet-${each.value.tier}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[each.value.region].name
  address_prefixes     = [each.value.cidr]
}

# Output: the for_each keys — one "region-tier" pair per subnet created.
output "subnet_keys" { value = keys(azurerm_subnet.this) }
