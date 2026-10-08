# Lab 26 — The `count` meta-argument.
# `count` creates N copies of a resource. Each copy is addressed as resource.name[0],
# resource.name[1], ... Use count when the copies are identical and index-addressed.

# locals: named values computed once and reused in this file. Simpler than repeating
# strings, and unlike variables they are not set from outside.
locals {
  rg = "rg-count-meta"
  st = lower("stcount${random_string.suffix.result}")
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

# Storage account: Azure's blob/file/queue storage. The name must be globally
# unique and lowercase, hence the random suffix. Referencing the resource group
# with azurerm_resource_group.this.name (instead of a string) creates an implicit
# dependency, so Terraform always creates the group first.
resource "azurerm_storage_account" "this" {
  name                     = local.st
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# count = 3 → Terraform creates 3 containers: data-0, data-1, data-2.
# count.index is the current iteration index (0-based).
resource "azurerm_storage_container" "data" {
  count                 = 3
  name                  = "data-${count.index}" # data-0, data-1, data-2
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Output: values printed after `terraform apply` (also with `terraform output`).
# When a resource uses count, you reference it as a LIST: resource.name[*].name.
# The [*] "splat" collects the .name attribute from every instance into one list.
output "container_names" {
  value = azurerm_storage_container.data[*].name
}
