# Lab 118 — the change → plan → apply loop.
# A storage account + container + a blob with source_content. Change the blob's
# source_content, then `terraform plan` shows the in-place update — that diff is
# how professionals review changes.
# `locals` are named values computed in-code. The storage account name embeds a
# random suffix so it is globally unique in Azure.
locals {
  st = lower("stchange${random_string.suffix.result}")
}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Container for the resources below; the plan/apply loop of this lab starts here.
resource "azurerm_resource_group" "this" {
  name     = "rg-changes"
  location = "eastus"
}

# A general-purpose storage account. Existing, unchanged attributes (tier,
# replication, location) stay "no-op" in plans — only what you edit diffs.
resource "azurerm_storage_account" "this" {
  name                     = local.st
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# A blob container ("folder") inside the storage account. Created after the
# account because of the `.name` reference — Terraform orders it automatically.
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# A single text blob whose CONTENT is managed by Terraform via source_content.
# Edit this string and `terraform plan` shows an in-place update
# (`~` = update, no destroy/create) — that diff is the review artifact of this lab.
resource "azurerm_storage_blob" "readme" {
  name                   = "readme.txt"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source_content         = "Version 2 of the readme\n"
}

# Output the blob's URL so you can verify the new content in a browser.
output "blob_url" { value = azurerm_storage_blob.readme.url }
