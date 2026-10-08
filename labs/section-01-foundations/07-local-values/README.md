# 07 — Local values

`locals` centralise derived values so they aren't repeated. This lab reuses the same
VNet from lab 06 but expresses every name and prefix through locals, and builds a common
tags map that every resource shares.

Notice the `merge()` function that combines common tags with resource-specific tags.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-foundation-eastus` | Name built by interpolation |
| `azurerm_virtual_network.this` | `vnet-foundation` | Tagged `tier = "network"` via `merge()` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/07-local-values
terraform init
terraform plan
terraform apply
terraform output tags
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-foundation-eastus`. Its **Tags** tab shows
`project = foundation`, `managedby = terraform`, `section = 01-foundations`. Open the
`vnet-foundation` resource → **Tags** and you'll see those three *plus*
`tier = network` — the result of `merge(local.common_tags, { tier = "network" })`.

## Key concepts / gotchas

- `locals` are computed once per run and referenced as `local.<name>` (singular, vs the
  block being `locals`).
- Locals can reference each other: `rg_name` uses `local.project` and `local.region`,
  so changing the region string changes the resource group name too.
- `"rg-${local.project}-${local.region}"` is **string interpolation** — `${}` evaluates
  an expression inside a string.
- A common tags map plus `merge()` is the standard pattern for consistent tagging:
  every resource gets the base tags, and `merge` adds resource-specific ones (later
  values win on key conflicts).
- Unlike variables, locals cannot be set from outside — they are purely internal.