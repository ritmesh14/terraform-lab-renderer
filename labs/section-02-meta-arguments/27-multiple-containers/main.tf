# Lab 27 — count from a variable (assignment).
# Same as lab 26 but the count is driven by a variable, so callers change the
# number of containers via tfvars/CLI without editing code.

# Input variable: lets the caller choose how many containers to create via
# -var / terraform.tfvars, without editing code. The validation block fails the
# plan early with a friendly message instead of a cryptic Azure error later.
variable "container_count" {
  type    = number
  default = 3
  validation {
    condition     = var.container_count > 0 && var.container_count <= 10
    error_message = "Keep between 1 and 10."
  }
}

# locals: named values computed once and reused in this file. lower() makes the
# name lowercase (Azure storage accounts must be all lowercase) and the random
# suffix makes it globally unique.
locals {
  st = lower("stcont${random_string.suffix.result}")
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
  name     = "rg-multi-containers"
  location = "eastus"
}

# Storage account: referencing the resource group with
# azurerm_resource_group.this.name (instead of a plain string) creates an
# implicit dependency, so Terraform always creates the group first.
resource "azurerm_storage_account" "this" {
  name                     = local.st
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# count comes from the variable now. Try: terraform apply -var=container_count=5
resource "azurerm_storage_container" "data" {
  count                 = var.container_count
  name                  = "tier-${count.index}"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Outputs: printed after apply (also with `terraform output`). A count resource
# is a LIST of instances, so length() counts them and the [*] splat collects all
# names into one list.
output "count" { value = length(azurerm_storage_container.data) }
output "container_names" { value = azurerm_storage_container.data[*].name }
