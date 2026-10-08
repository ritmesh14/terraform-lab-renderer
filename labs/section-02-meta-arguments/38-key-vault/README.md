# Lab 38 — Azure Key Vault via Terraform

Key Vault stores secrets, keys and certificates. This lab creates a vault, a secret, and
grants the current user get/list permissions using a `data` block for the current
principal.

> Vault names are globally unique, 3–24 chars, alphanumerics + hyphens only.

## What it creates

| Terraform resource                      | Azure name                       | Notes                                       |
| --------------------------------------- | -------------------------------- | ------------------------------------------- |
| `azurerm_resource_group.this`           | Resource group `rg-kv-meta`      | 1                                           |
| `azurerm_key_vault.this`                | Key Vault `kv-<random>`          | 1, Standard SKU, soft delete 7 days         |
| `azurerm_key_vault_secret.db_password`  | Secret `db-password`             | 1, value comes from `var.db_password`       |
| `data.azurerm_client_config.current`    | (no resource)                    | reads tenant_id / object_id of `az login` user |

## Commands

```bash
cd 38-key-vault
az login            # the data source + access policy use THIS identity
terraform init
terraform plan
terraform apply -var=db_password="<a strong password>"
terraform output vault_name
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-kv-meta` → the Key Vault `kv-<random>` →
  **Objects → Secrets**: the `db-password` secret is there.
- Open the secret → **Current version** → *Show secret value* to read it (you can,
  because the access policy granted your user `Get`/`Set`).
- **Access configuration → Access policies** shows your account with the five
  permissions from the code.

## Key concepts / gotchas

- `data "azurerm_client_config"` is a **data source**: it reads existing facts (who is
  signed in, which tenant) instead of creating anything. Its `object_id` feeds the
  access policy, so whoever ran `az login` gets access.
- `soft_delete_retention_days = 7` means a deleted secret/vault is recoverable for a
  week — re-creating a vault with the same name within that window fails with a
  conflict unless you purge or wait.
- `purge_protection_enabled = false` is lab-only; production vaults should enable it
  (nothing can hard-delete the vault, not even its owner).
- The secret value comes from `var.db_password` (`sensitive`, no default — Terraform
  prompts or takes `-var`), so no secret literal ever sits in the source. It is still
  written into Terraform **state in plain text** — for real secrets use `-var` from a
  secure prompt, or reference an existing vault secret with a data source.
- `sensitive = true` on the output only redacts the CLI output, not the state file.
