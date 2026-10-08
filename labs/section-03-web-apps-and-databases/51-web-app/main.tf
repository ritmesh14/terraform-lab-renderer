# Lab 51 — Azure Web App (App Service).
# App Service is the managed PaaS for web apps: no VM, no OS patching, easy scale.
# We create a Service Plan (the compute) + a Linux Web App (the app).

# locals = named values computed once. Keeping the resource-group name here
# means one place to change it.
locals { rg = "rg-webapp" }

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# A resource group is Azure's folder/container: every resource lives in one,
# and deleting the group deletes everything in it.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# The Service Plan = the compute tier. sku_name "B1" = small shared Linux.
# os_type must match the web app (Linux here).
resource "azurerm_service_plan" "this" {
  name                = "asp-webapp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# A Linux Web App runs your code. Names are globally unique (web app DNS).
resource "azurerm_linux_web_app" "this" {
  name                = "app-webapp-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id

  site_config {
    application_stack {
      node_version = "18-lts" # the runtime/language stack
    }
  }
}

# Outputs print values after apply — here the live site URL, e.g. https://app-webapp-ab12cd.azurewebsites.net
output "default_hostname" { value = azurerm_linux_web_app.this.default_hostname }
