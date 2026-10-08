# ---------------------------------------------------------------------------
# Lab 12 — Subnet as a separate resource
# Builds: resource group "rg-separes-foundation", VNet "vnet-separes" and two
# standalone subnets snet-web / snet-app.
# Teaches: azurerm_subnet as its own resource (vs the inline subnets of lab 06),
# which unlocks per-subnet NSGs, delegations and service endpoints.
# ---------------------------------------------------------------------------

locals {
  region = "eastus"
  rg     = "rg-separes-foundation"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = local.region
}

# The VNet holds the address space but defines NO subnets here.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-separes"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.80.0.0/16"]
}

# Each subnet is its OWN resource. This is more flexible than inline subnets:
# you can add NSGs, delegations, service endpoints, and peer per subnet.
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.80.1.0/24"]
}

# Second subnet, same pattern — for the app tier.
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.80.2.0/24"]
}

# The web subnet's id is what NICs (lab 13) will attach to.
output "web_subnet_id" { value = azurerm_subnet.web.id }
