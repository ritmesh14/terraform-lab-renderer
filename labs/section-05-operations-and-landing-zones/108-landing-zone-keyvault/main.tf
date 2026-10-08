# Lab 108 — Landing Zone: Key Vault.
#  - A vault in the security RG; purge protection enabled (certs/secrets can't be
#    hard-deleted for 7 days).
#  - An access policy granting the current user Get/Set/Delete/Purge on secrets.
#  - One stored secret (sql-admin-password) the app can pull at runtime.
# Reads facts about the identity Terraform runs as: its Azure AD tenant_id and the
# user's object_id. Both are needed — a vault is locked to a tenant, and an access
# policy must name exactly WHO gets which permissions.
data "azurerm_client_config" "current" {}

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Security RG — the landing-zone home for secrets (see lab 103's layout).
resource "azurerm_resource_group" "sec" {
  name     = "rg-lz-kv"
  location = "eastus"
}

# Key Vault: the security store for secrets, keys and certificates.
resource "azurerm_key_vault" "this" {
  # Interpolation keeps the globally-unique vault name collision-free.
  name                       = "kv-lz-${random_string.suffix.result}"
  location                   = azurerm_resource_group.sec.location
  resource_group_name        = azurerm_resource_group.sec.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id # vault is tenant-bound
  sku_name                   = "standard"                                   # standard vs premium (HSM keys)
  soft_delete_retention_days = 7                                            # deleted vaults/secrets are recoverable for 7 days
  purge_protection_enabled   = true                                         # even with permission, a purge is refused within that window

  # Access policy = classic (non-RBAC) permission model: an explicit allow-list per identity.
  # This one gives the current user the secret lifecycle: read (Get/List),
  # write (Set), and the delete path (Delete → soft-deleted → Purge or Recover).
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }
}

# A stored secret: the "sql-admin-password" the app pulls at runtime instead of
# hardcoding credentials. The value is random-ish but generated deterministically
# from the stable suffix.
resource "azurerm_key_vault_secret" "sql_admin" {
  name         = "sql-admin-password"
  value        = "ChangeMe-${random_string.suffix.result}"
  key_vault_id = azurerm_key_vault.this.id
}

# Output: the vault name — what other labs / apps reference by name.
output "vault_name" { value = azurerm_key_vault.this.name }
