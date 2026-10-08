# Lab 39 — Data sources.
# Teaches: a `data` block that READS an existing resource group (creating nothing),
# a variable that points it at the right name, and reusing the data source's
# attributes (name, location, tags) in a real resource.
# A `data` block READS an existing resource instead of creating one. Useful when
# something is managed elsewhere but you need its attributes here.

# Point this at a resource group that ALREADY exists in your subscription
# (e.g. create one with: az group create -n rg-already-here -l eastus).
variable "existing_rg_name" {
  type    = string
  default = "rg-already-here"
}

# Read (do not own) the existing resource group.
data "azurerm_resource_group" "existing" {
  name = var.existing_rg_name
}

# Create a storage account IN that existing RG, reusing its name/location.
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Storage account: created INSIDE the discovered resource group — its name and
# location come from the data source, not from hard-coded strings.
resource "azurerm_storage_account" "this" {
  name                     = lower("stdata${random_string.suffix.result}")
  resource_group_name      = data.azurerm_resource_group.existing.name
  location                 = data.azurerm_resource_group.existing.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Outputs: values read FROM the existing group. rg_location is known at plan time
# (the group already exists), unlike resource attributes Azure assigns at apply.
output "rg_location" { value = data.azurerm_resource_group.existing.location }
# rg_tags shows the group's tags ({} if it has none) — handy for inheritance.
output "rg_tags" { value = data.azurerm_resource_group.existing.tags }
