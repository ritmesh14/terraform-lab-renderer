# 04 — References to named values

Terraform references let one resource consume another's attributes. This lab
demonstrates the three reference families — `local.*`, `var.*` and resource refs —
so the same value is never written twice. The storage account name is even derived
from the resource group's id with a hash, showing that references can feed
expressions, not just plain attributes.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.core` | `rg-refs-foundation` | From `local.rg_name` |
| `azurerm_storage_account.logs` | `stlogs<6-char md5>` | Name derived from the RG's id |

## Reference cheat sheet

| Reference | Looks like | Refers to |
|---|---|---|
| Resource | `azurerm_resource_group.core.id` | another resource attribute |
| Local | `local.rg_name` | a value in `locals {}` |
| Variable | `var.location` | an input variable |

The same storage account is created, but every attribute is now *referenced* rather than
repeated — the single source of truth pattern you should use everywhere.

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/04-named-value-references
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

Try overriding the variable to see `var.location` in action:

```bash
terraform apply -var "location=westeurope"
```

## What to see in the Azure portal

**Resource groups** → `rg-refs-foundation` → the storage account whose name starts with
`stlogs` followed by 6 hash characters. Those characters are the first 6 of the
`md5(azurerm_resource_group.core.id)` hash — deterministic, so re-applying never
changes the name (but it is not random, and not saved in state like `random_string`).

## Key concepts / gotchas

- References create **implicit dependencies**: because the storage account references
  `azurerm_resource_group.core`, Terraform automatically creates the RG first.
- `local.*` = value computed inside this config; `var.*` = value passed in from outside
  (default, tfvars, or `-var`); `resource ref` = an attribute of something Terraform
  creates itself.
- `md5()` always returns the same hash for the same input — handy for deterministic
  name suffixes, but unlike `random_string` it is not stored in state, so if the input
  (the RG id) changes, the name changes too.
- `substr(..., 0, 6)` takes the first 6 characters; `lower()` makes the name lowercase
  as storage account names require.