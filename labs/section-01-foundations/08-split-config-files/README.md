# 08 — Split configuration files

Real configs grow. Split them by concern:

- `terraform.tf` — versions & provider
- `locals.tf` — derived values
- `main.tf` — resources
- `outputs.tf` — outputs

Terraform merges every `*.tf` file in a directory into one logical configuration, so the
order does not matter. This lab is the **same VNet** as lab 07, just split across files —
the pattern every later lab follows.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-split-eastus` | Name built in `locals.tf` |
| `azurerm_virtual_network.this` | `vnet-split` | `10.40.0.0/16`, shared tags |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/08-split-config-files
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-split-eastus` → `vnet-split`. Nothing is new Azure-wise —
the point of this lab is that a config split across four files behaves identically to
one single file.

## Key concepts / gotchas

- Terraform **merges all `*.tf` files** in a folder into one configuration — file
  boundaries are only for humans; there is no import or include between them.
- **File names don't matter** for evaluation order: `main.tf` can reference `local.*`
  from `locals.tf` regardless of alphabetical order.
- Convention: `terraform.tf` (or `providers.tf`) for versions/provider, `variables.tf`
  for inputs, `locals.tf` for derived values, `outputs.tf` for outputs.
- One exception to "order doesn't matter": a directory must contain at most one `locals
  {}` block per *name* — duplicate local names across files are an error, exactly as if
  they were in one file.
- Watch out for stray files: any `*.tf` in the directory is loaded, so leftover copies
  of a lab can cause duplicate-resource errors.