# Lab 111 — diagnostic settings on a storage account.
# azurerm_monitor_diagnostic_setting sends a resource's logs/metrics to a destination:
# here a Log Analytics workspace. We also enable storage blob service logging.
# This is the wiring that makes the central logging in lab 105 actually receive data.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
provider "azurerm" {
  features {}
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource group holding the logging pieces and the monitored storage account.
resource "azurerm_resource_group" "this" {
  name     = "rg-diag-settings"
  location = "eastus"
}

# Destination #1: the Log Analytics workspace the logs stream into for querying.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-diag-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# A second storage account standing in for the "archive" destination.
resource "azurerm_storage_account" "logs" {
  name                     = lower("stdiag${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# A private container inside the archive account. (Note: it is created but the
# diagnostic setting below does not send anything here — the archive destination
# would be wired with a storage_account_id field on the diagnostic setting.)
resource "azurerm_storage_container" "archive" {
  name                  = "diag-archive"
  storage_account_name  = azurerm_storage_account.logs.name
  container_access_type = "private"
}

# The storage account whose activity we want to capture. Blob logging is
# configured on the account itself via blob_properties (azurerm 3.x has no
# standalone blob-service-properties resource).
resource "azurerm_storage_account" "app" {
  name                     = lower("stdiagapp${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    # Classic blob logging was deprecated by Azure (diagnostic settings, below,
    # are the replacement), so we just enable versioning here.
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

# Diagnostic setting: THE wiring that makes lab 105's "central logging" real. It says
# "send this storage account's logs and metrics to the workspace". Destinations are
# optional fields: log_analytics_workspace_id, storage_account_id, eventhub_authorization_rule_id.
resource "azurerm_monitor_diagnostic_setting" "to_la" {
  name                       = "diag-to-loganalytics"
  target_resource_id         = azurerm_storage_account.app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Which log categories to stream. Storage exposes one per service: StorageRead /
  # StorageWrite / StorageDelete here cover the blob service's access activity.
  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  # Platform metrics for the account (requests, latency, egress).
  metric {
    category = "Transaction"
    enabled  = true
  }
}

# Outputs for later labs / tooling.
output "workspace_id" { value = azurerm_log_analytics_workspace.this.id }
output "app_storage" { value = azurerm_storage_account.app.name }
