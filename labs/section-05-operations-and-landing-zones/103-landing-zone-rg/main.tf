# Lab 103 — Landing Zone: resource groups.
# The Azure landing-zone pattern separates concerns by RG: network, data, security.
# We create three RGs sharing common tags, driven by a landing_zone_name variable.
# Which landing zone this is — one name labels every RG (app1, app2, shared, ...).
variable "landing_zone_name" {
  type    = string
  default = "app1"
}

# Azure region all RGs are created in.
variable "location" {
  type    = string
  default = "eastus"
}

# locals = computed values used more than once. Names and tags are derived here
# so every RG stays consistent — change the name in one place, all RGs follow.
locals {
  # Naming convention: rg-<landing-zone>-<function>.
  rg_names = {
    network  = "rg-${var.landing_zone_name}-net"
    data     = "rg-${var.landing_zone_name}-data"
    security = "rg-${var.landing_zone_name}-sec"
  }
  # Tags applied to every RG: tags power cost reports, filtering and governance.
  common_tags = {
    landing_zone = var.landing_zone_name
    managedby    = "terraform"
  }
}

# Three RGs, one per concern of the landing zone. Same shape, different local name +
# shared tags — this is the "standardized building block" idea.
resource "azurerm_resource_group" "network" {
  name     = local.rg_names.network
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "data" {
  name     = local.rg_names.data
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "security" {
  name     = local.rg_names.security
  location = var.location
  tags     = local.common_tags
}

# Output: the RG name map, handy for the next labs (e.g. pass rg-vnet-… as a var).
output "rg_names" { value = local.rg_names }
