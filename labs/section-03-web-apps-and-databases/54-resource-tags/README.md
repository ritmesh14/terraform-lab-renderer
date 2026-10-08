# Lab 54 — Resource tags

Tags drive cost reporting, billing, and automation. Standardise them in `locals` and
spread them everywhere with `merge()` — one variable change retags everything.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-tags-<environment>` | `tags = local.common_tags` |
| `azurerm_storage_account` | `sttags<environment><suffix>` | `tags = merge(local.common_tags, { tier = "storage" })` |
| outputs | `rg_tags`, `st_tags` | the applied tag maps, for verification |

`environment` is a variable with default `"dev"` — the tag value and both resource
names follow it.

## Commands

Prerequisite: `az login`.

```bash
cd 54-resource-tags
terraform init
terraform plan
terraform apply
terraform output st_tags
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-tags-dev** (name changes if you set a different `environment`):

- Open the resource group → **Tags**: `environment = dev`, `managedby = terraform`,
  `costcenter = cc-100`.
- Open the storage account `sttags...` → **Tags**: those three **plus**
  `tier = storage` — the resource-specific tag added by `merge()`.
- In **Cost Management**, tag values can be used to group/bill resources.

## Key concepts / gotchas

- **`locals` are computed values**, not inputs: `common_tags` is built once from
  `var.environment` and reused, so there's one source of truth.
- **`merge()` layers tag sets** — common tags first, resource-specific tags last
  (later keys win in a merge).
- **`sensitive` is not needed for tags** — but changing `var.environment` changes the
  *names* of the resources (`rg-tags-prod` ≠ `rg-tags-dev`), which means destroy +
  recreate, not an in-place retag. Watch `terraform plan` show `-/+`.
- **Azure enforces no tags by default** — consistency is your job; tools like Azure
  Policy can require tags.
- Tag values you plan to filter on should be stable — that's why `environment` is a
  variable rather than a literal repeated in every block.
