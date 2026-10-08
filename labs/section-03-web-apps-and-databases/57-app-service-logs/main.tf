# Lab 57 — App Service logs.
# Turn on App Service logging to a storage account + the filesystem. The `logs`
# block streams http logs to blob storage and app logs to the file system.

# Storage account names are globally unique, 3-24 chars, lowercase letters and
# digits only — hence lower() and the random suffix.
locals { st = lower("stapplogs${random_string.suffix.result}") }

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
  name     = "rg-applogs"
  location = "eastus"
}

# Storage account to hold HTTP logs.
resource "azurerm_storage_account" "logs" {
  name                     = local.st
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# The Service Plan = the compute tier the web app runs on (B1 Basic, Linux).
resource "azurerm_service_plan" "this" {
  name                = "asp-applogs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# The Linux Web App that logs to the storage account above.
resource "azurerm_linux_web_app" "this" {
  name                = "app-applogs-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  site_config {
    application_stack { node_version = "18-lts" }
  }

  # Logging config. http_logs → blob storage; application logs → filesystem.
  # http_logs takes EITHER azure_blob_storage OR file_system, not both.
  # application_logs takes a file_system_level plus a file_system block
  # (which needs retention_in_mb).
  logs {
    http_logs {
      azure_blob_storage {
        sas_url           = azurerm_storage_account.logs.primary_blob_connection_string
        retention_in_days = 7
      }
    }
    application_logs {
      # Linux apps: application log level + (optionally) a blob destination.
      file_system_level = "Information"
    }
  }
}

# Outputs print values after apply — the app's live URL (hit it to make logs appear).
output "default_hostname" { value = azurerm_linux_web_app.this.default_hostname }
