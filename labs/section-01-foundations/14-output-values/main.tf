# ---------------------------------------------------------------------------
# Lab 14 — Output values
# Builds: resource group "rg-output-foundation" + storage account "stout<suffix>".
# Teaches: `output` blocks — plain, described and `sensitive` outputs — and how
# `terraform output` retrieves values after apply.
# ---------------------------------------------------------------------------

locals {
  rg = "rg-output-foundation"
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource group: the container that groups all resources for this lab in Azure.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}

# Storage account whose attributes the outputs will expose.
resource "azurerm_storage_account" "this" {
  name                     = lower("stout${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
