# Lab 32 — multiple public IPs with count + format().
# Teaches: count with a local, count.index inside format() for zero-padded names,
# and the [*] splat on a count resource.

# locals: how many public IPs to create. Changing this number and re-applying
# scales the fan-out up or down.
locals {
  ip_count = 3
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = "rg-multi-pips"
  location = "eastus"
}

# format("pip-%02d", 1) → "pip-01" (zero-padded, 2 digits). %02d = at least 2 digits.
resource "azurerm_public_ip" "this" {
  count               = local.ip_count
  name                = format("pip-%02d", count.index + 1)
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Output: the [*] splat collects .ip_address from every count instance into a
# list, so you get 3 addresses. The .ip_address attribute is only known AFTER
# apply — the plan shows <computed> (Terraform learns it from Azure).
output "ips" { value = azurerm_public_ip.this[*].ip_address }
