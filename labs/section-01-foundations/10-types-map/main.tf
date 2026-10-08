# ---------------------------------------------------------------------------
# Lab 10 — Types: map (and for_each)
# Builds: resource group "rg-map-foundation", VNet "vnet-map" and three subnets
# snet-web / snet-app / snet-data, one per map key.
# Teaches: map(object) types and `for_each` with each.key / each.value — the
# idiomatic way to create N resources from N map entries.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Lab 10 — Types: map (and for_each)
# Builds: resource group "rg-map-foundation", VNet "vnet-map" and three subnets
# snet-web / snet-app / snet-data, one per map key.
# Teaches: map(object) types and `for_each` with each.key / each.value — the
# idiomatic way to create N resources from N map entries.
# ---------------------------------------------------------------------------

locals {
  region = "eastus"
  rg     = "rg-map-foundation"

  # A MAP: keys are meaningful ("web", "app", "data"); values are OBJECTS.
  # Maps are ideal when you address things by role rather than by position.
  subnets = {
    web  = { prefix = "10.60.1.0/24", nsg = true }
    app  = { prefix = "10.60.2.0/24", nsg = true }
    data = { prefix = "10.60.3.0/24", nsg = false }
  }
}

# Resource group: the container that groups all resources for this lab in Azure.
# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = local.region
}

# The VNet the three subnets live in.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-map"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.60.0.0/16"]
}

# `for_each` over a map creates one resource per KEY. Inside the block, each.key
# is the map key ("web"), each.value is the object ({prefix, nsg}).
# NOTE: the nsg flag in the map is declared but not used in this lab — the
# map(object) shape here is exactly what lab 11 turns into a variable.
resource "azurerm_subnet" "this" {
  for_each             = local.subnets
  name                 = "snet-${each.key}" # e.g. snet-web
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.prefix]
}

# A `for` over a map: k=key, s=value. Builds a map of name -> id.
output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}
