# Lab 102 — management locks.
# A lock prevents delete (CanNotDelete) or all changes (ReadOnly) at the resource
# scope. We put a CanNotDelete lock on a storage account → `terraform destroy`
# (or a portal click) will fail until the lock is removed.
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource group holding the demo storage account.
resource "azurerm_resource_group" "this" {
  name     = "rg-locks"
  location = "eastus"
}

# Storage account: the resource we'll protect. Names must be globally unique and
# lowercase (3-24 chars), hence the lower() + random suffix.
resource "azurerm_storage_account" "this" {
  # lower(...) flattens everything to lowercase — storage account names reject capitals.
  name                     = lower("stlock${random_string.suffix.result}")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Management lock: a Azure-level guardrail, independent of RBAC — even an Owner hits it.
#   CanNotDelete = reads/writes allowed, delete refused
#   ReadOnly     = only reads allowed (no writes, no deletes, and portal edits fail)
resource "azurerm_management_lock" "st" {
  name       = "do-not-delete"
  scope      = azurerm_storage_account.this.id # could also be a RG or subscription
  lock_level = "CanNotDelete"
  notes      = "Protected by Terraform; remove lock before destroying."
}

# Output: the lock's Azure resource ID (locks are resources you can list/read via API).
output "lock_id" { value = azurerm_management_lock.st.id }
