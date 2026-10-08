# Lab 38 — Azure Key Vault.
# Teaches: a data source (azurerm_client_config) that reads facts about the
# signed-in principal, a resource with a nested access_policy block, and marking
# outputs sensitive so values are not printed in clear.
# Key Vault stores secrets/keys/certs centrally so they never sit in code or state
# on a laptop. We create a vault, grant the current user access, and store a secret.

# The secret VALUE comes from an input, never from the source: sensitive = true
# hides it in plan/apply output, and with no default Terraform prompts for it
# (or pass -var / tfvars). Matches the section-01 convention for key material.
variable "db_password" {
  type      = string
  sensitive = true
}

# Read the current signed-in principal (object_id) to grant it permissions.
data "azurerm_client_config" "current" {}

# locals: the vault name (random suffix keeps it globally unique).
locals {
  # Vault names are globally unique, 3-24 chars, alphanumerics + hyphens only.
  vault_name = "kv-${random_string.suffix.result}"
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
  name     = "rg-kv-meta"
  location = "eastus"
}

# Key Vault: the vault itself. tenant_id comes from the data source (who owns the
# vault), and the access_policy block grants YOUR user the listed secret permissions.
resource "azurerm_key_vault" "this" {
  name                       = local.vault_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7     # recover deleted secrets for 7 days
  purge_protection_enabled   = false # lab: allow hard purge; enable in prod

  # access_policy grants a principal (here: you) permissions on the vault.
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

# A secret stored in the vault. The VALUE comes from var.db_password — never a
# literal in the source. It still lands in state (see README gotchas).
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.this.id
}

# Outputs: the vault name (plain) and the secret's ID (marked sensitive so it is
# redacted in the CLI; the value itself never leaves the vault in code).
output "vault_name" { value = azurerm_key_vault.this.name }
# versionless_id is a stable reference to the secret (not the value).
output "secret_versionless_id" {
  value     = azurerm_key_vault_secret.db_password.versionless_id
  sensitive = true
}
