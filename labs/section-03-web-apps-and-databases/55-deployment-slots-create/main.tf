# Lab 55 — Deployment slots (create).
# Slots let you stage a build and warm it before swapping into production. This
# lab creates a web app PLUS a "staging" slot. Slots need a Basic+ plan.

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
  name     = "rg-slots"
  location = "eastus"
}

# The Service Plan = the compute tier. Slots require Basic or higher (B1 is fine).
resource "azurerm_service_plan" "this" {
  name                = "asp-slots"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# The production app. The slot below hangs off this resource.
resource "azurerm_linux_web_app" "this" {
  name                = "app-slots-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  site_config {
    application_stack { node_version = "18-lts" }
  }
}

# A staging slot of the web app above. It shares the plan and has its own hostname.
# The slot resource takes app_service_id (no separate location/app_id — it
# inherits both from the parent app).
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.this.id
  site_config {
    application_stack { node_version = "18-lts" }
  }
}

# Outputs print values after apply — each slot gets its own URL, with the slot
# name as a subdomain: https://app-slots-<suffix>-staging.azurewebsites.net
output "prod_hostname" { value = azurerm_linux_web_app.this.default_hostname }
output "staging_hostname" { value = azurerm_linux_web_app_slot.staging.default_hostname }
