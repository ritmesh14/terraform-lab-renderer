# Lab 28 — The `for_each` meta-argument.
# for_each creates one resource per element of a SET or MAP. Each copy is
# addressed by its KEY: resource.name["key"]. Prefer for_each over count when
# copies differ in config and are best addressed by a meaningful key.

# locals: the for_each collection and the storage-account name, computed once.
locals {
  # toset() converts a list to a set (unique, unordered). for_each over a set
  # creates one resource per string: "dev", "stg", "prod".
  stages = toset(["dev", "stg", "prod"])
  st     = lower("stforeach${random_string.suffix.result}")
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
  name     = "rg-foreach-meta"
  location = "eastus"
}

# Storage account: referencing azurerm_resource_group.this.name creates an
# implicit dependency, so Terraform always creates the group first.
resource "azurerm_storage_account" "this" {
  name                     = local.st
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# for_each over the set. each.value is the string ("dev"); with a set, each.key
# and each.value are the same.
resource "azurerm_storage_container" "stage" {
  for_each              = local.stages
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Output: a for_each resource is a MAP of instances, so keys() lists the keys
# ("dev", "stg", "prod") and azurerm_storage_container.stage["dev"] would address
# a single instance by key.
output "containers" { value = keys(azurerm_storage_container.stage) }
