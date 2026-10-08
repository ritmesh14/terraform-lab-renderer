# Lab 53 — The lifecycle meta-argument.
# lifecycle {} changes how Terraform treats a resource over time:
#   - create_before_destroy: build the new version BEFORE removing the old.
#   - prevent_destroy: refuse to destroy (safety for prod databases).
#   - ignore_changes: let chosen attributes drift (e.g. tags set by another tool).

# Storage account names are globally unique, 3-24 chars, lowercase letters and
# digits only — hence lower() and the random suffix.
locals { st = lower("stlife${random_string.suffix.result}") }

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
  name     = "rg-lifecycle"
  location = "eastus"
}

# A storage account = Azure's blob/file/queue service. Standard + LRS is the
# cheapest replication (3 copies, one datacenter).
resource "azurerm_storage_account" "this" {
  name                     = local.st
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = { "owner" = "platform-team" }

  lifecycle {
    # Another tool (Azure Policy) retags this account. Don't fight it in plan.
    ignore_changes = [tags["owner"]]
  }
}

# A blob container inside the storage account — like a folder for blobs.
resource "azurerm_storage_container" "this" {
  name                  = "lifecycle"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"

  lifecycle {
    # On replace: create the NEW container first, then delete the old.
    create_before_destroy = true
  }
}
