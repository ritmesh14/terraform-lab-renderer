# Lab 106 — Landing Zone: app storage.
# A general-purpose v2 storage account with two private containers and TLS 1.2
# enforced. Lives in the data RG; public blob access is OFF.
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Data RG — the landing-zone home for app data (see lab 103's layout).
resource "azurerm_resource_group" "data" {
  name     = "rg-lz-data"
  location = "eastus"
}

# General-purpose v2 storage account for the application's blobs.
# Landing-zone hardening below: no blob inside this account may be made public,
# regardless of a container's own setting (allow_nested_items_to_be_public = false).
resource "azurerm_storage_account" "app" {
  # lower() + random suffix: storage names must be globally unique, lowercase, 3-24 chars.
  name                            = lower("stlzapp${random_string.suffix.result}")
  resource_group_name             = azurerm_resource_group.data.name
  location                        = azurerm_resource_group.data.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

# Two private containers (blob "folders"): uploads for incoming data, archive for cold data.
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.app.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "archive" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.app.name
  container_access_type = "private"
}

# Output: the account name (needed by az storage CLI commands / connections).
output "storage_name" { value = azurerm_storage_account.app.name }
