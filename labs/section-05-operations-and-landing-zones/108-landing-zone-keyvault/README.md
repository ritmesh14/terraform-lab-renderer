# Lab 108 — Landing Zone — Key Vault

A vault in the security RG to hold the SQL admin password (and any other secret). The
current user gets secret permissions; purge protection is enabled.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `data.azurerm_client_config.current` | — | tenant_id + object_id of the caller |
| `random_string.suffix` | — | 6 chars making the vault name unique |
| `azurerm_resource_group.sec` | `rg-lz-kv` | eastus |
| `azurerm_key_vault.this` | `kv-lz-<suffix>` | standard sku, 7-day soft delete, purge protection ON |
| `azurerm_key_vault_secret.sql_admin` | `sql-admin-password` | value hidden in output |
| output `vault_name` | — | Vault name |

## Commands

Prerequisite: `az login` (the access policy is granted to that identity). No tfvars.

```bash
cd 108-landing-zone-keyvault
terraform init
terraform plan
terraform apply
terraform output vault_name
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-lz-kv** → vault `kv-lz-<suffix>`:

- **Objects → Secrets**: `sql-admin-password` with a version and activation date.
  Click it → **Current Version → Show secret value** to reveal it.
- **Settings → Access policies**: your user with Get/List/Set/Delete/Purge/Recover.
- **Overview → Properties**: "Soft delete: Enabled (7 days)",
  "Purge protection: Enabled".

## Key concepts / gotchas

- **Soft delete + purge protection are the vault's safety net**: deleting a secret
  (or the whole vault) puts it in a recoverable state for `soft_delete_retention_days`;
  purge protection means even the Purge permission can't hard-delete during that window.
  With both on, `terraform destroy` removes the vault but recovery is still possible
  for 7 days — and re-creating a vault with the same name fails until the soft-deleted
  one is purged or the window passes.
- **`access_policy` vs RBAC**: this vault uses the classic access-policy model —
  permissions are attached directly to the vault resource. Newer landing zones set
  `enable_rbac_authorization = true` and grant roles on the vault's scope instead.
- **The secret value does show up in Terraform state** (it's not a `sensitive`
  variable). For real credentials, feed `value` from a variable marked sensitive,
  a Key Vault data source, or generate it — not a hardcoded pattern.
- **Why the app cares**: services read secrets at runtime
  (`az keyvault secret show --vault-name kv-lz-xxxx --name sql-admin-password`),
  so no credential ever lands in source control.
- Vault **names are globally unique** in Azure — that's what the random suffix buys.
