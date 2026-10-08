# ---------------------------------------------------------------------------
# Lab 15 — Public IP address
# Builds: resource group "rg-pip-foundation" + public IP "pip-web-01".
# Teaches: azurerm_public_ip, allocation_method (Static/Dynamic) and SKU
# (Basic/Standard), and reading a computed address via an output.
# ---------------------------------------------------------------------------

locals {
  rg = "rg-pip-foundation"
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# A Public IP makes a resource reachable from the internet.
# - allocation_method: "Static" gets a fixed IP; "Dynamic" changes on stop.
# - sku: "Basic" (legacy) or "Standard" (required for zone-redundant LBs).
resource "azurerm_public_ip" "web" {
  name                = "pip-web-01"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The IP is only known AFTER creation. Read it from .ip_address in an output.
# With Static allocation the address stays with the resource even when the VM
# (in later labs) is stopped; with Dynamic it is released on stop.
output "public_ip" { value = azurerm_public_ip.web.ip_address }
