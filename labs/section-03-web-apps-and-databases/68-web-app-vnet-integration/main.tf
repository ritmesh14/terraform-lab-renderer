# Lab 68 — App Service VNet integration.
# When a database is private (no public access), the web app must integrate with
# a VNet to reach it. We create a subnet DELEGATED to App Service and wire the
# web app to it. vnet_route_all_enabled sends ALL traffic through the VNet.

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# A resource group is Azure's folder: everything this lab creates lives here.
resource "azurerm_resource_group" "this" {
  name     = "rg-webapp-vnet"
  location = "eastus"
}

# A virtual network is your private IP space in Azure — like an on-prem network.
# 10.253.0.0/16 = 65,536 private addresses carved into subnets below.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-webapp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.253.0.0/16"]
}

# A subnet DELEGATED to Microsoft.Web/serverFarms (required for regional VNet integration).
resource "azurerm_subnet" "webapp" {
  name                 = "snet-webapp"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.253.1.0/26"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# VNet integration needs Standard+ plan (B1 is too small).
# The Service Plan = the compute tier. Standard+ (S1 here) is required for
# regional VNet integration — B1 is too small.
resource "azurerm_service_plan" "this" {
  name                = "asp-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "S1"
}

# The Linux Web App that gets joined to the private subnet.
resource "azurerm_linux_web_app" "this" {
  name                = "app-vnet-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id

  # Bind the app to the delegated subnet → it can now reach private resources in the VNet.
  virtual_network_subnet_id = azurerm_subnet.webapp.id

  site_config {
    application_stack { node_version = "18-lts" }
    # vnet_route_all_enabled sends ALL outbound traffic through the VNet.
    # It lives inside site_config, not at the resource's top level.
    vnet_route_all_enabled = true
  }
}

# Outputs print values after apply — the app's live URL.
output "webapp_hostname" { value = azurerm_linux_web_app.this.default_hostname }
