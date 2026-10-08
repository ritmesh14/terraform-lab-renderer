# ---------------------------------------------------------------------------
# Lab 19 — Variable definition file (terraform.tfvars)
# Builds: resource group "rg-tfvars-foundation" + storage account named from
# tfvars-supplied values.
# Teaches: declaring variables WITHOUT defaults so they must be supplied, and
# auto-loading of terraform.tfvars / *.auto.tfvars.
# ---------------------------------------------------------------------------

# Declare inputs (no defaults → they MUST be supplied via tfvars or -var).
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "tier" { type = string }

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
  name     = "rg-tfvars-foundation"
  location = var.location
}

# Storage account — name/tier assembled from the tfvars-supplied variables.
resource "azurerm_storage_account" "this" {
  name                     = "${var.name_prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.tier
  account_replication_type = "LRS"
}
