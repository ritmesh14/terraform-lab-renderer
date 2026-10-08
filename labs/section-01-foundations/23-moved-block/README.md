# 23 — `moved` block (advanced refactoring)

Rename a resource's Terraform address **without destroying and recreating** the cloud
resource. Without `moved`, renaming `azurerm_storage_account.legacy` to `.this` would
plan a destroy + create. With `moved {}`, Terraform updates the state's address in place.

```hcl
moved {
  from = azurerm_storage_account.legacy
  to   = azurerm_storage_account.this
}
```

This lab declares the resource at its new address (`this`) with a `moved` from the old
address (`legacy`). On first apply it's a no-op since there's no prior state; once you've
applied with the old name elsewhere and rename, the moved block reconciles state.

Addressing: VNet `172.16.0.0/20`, subnet `172.16.0.0/26`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-moved-block` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-moved` | `172.16.0.0/20` (4,096 addresses) |
| `azurerm_subnet.web` | `snet-web` | `172.16.0.0/26` (64 addresses) |
| `azurerm_storage_account.this` | `stmoved<suffix>` | Declared at its **new** address |

## How to see the move actually happen

The moved block only does something when *state already exists under the old address*:

```bash
cd section-01-foundations/23-moved-block
terraform init
terraform apply                          # creates everything as .this
# ...simulate a rename: edit main.tf so the storage account block is named "legacy",
# apply, rename it back to "this" (moved block present), then:
terraform plan    # plan shows NO destroy/create — just the state address move
terraform apply
```

## What to see

- In the plan, Terraform reports it will move
  `azurerm_storage_account.legacy → azurerm_storage_account.this` with **no** resource
  being destroyed or recreated — the real Azure resource is untouched.
- `terraform state list` shows the address now as `azurerm_storage_account.this`.

## Key concepts / gotchas

- Terraform identifies resources by their **address in state**, not by their Azure name —
  renaming a block therefore looks like "delete old, create new" unless `moved` explains
  the rename.
- `moved` is **state-only surgery**: nothing happens in Azure; it's free (no API call for
  the move itself).
- Remove the `moved` block once every state that had the old address has applied the
  rename; leaving it is harmless but noise.
- `moved` also works across refactors like `count → for_each`, moving a resource into a
  module (`from = azurerm_x.y`, `to = module.new.azurerm_x.y`), and renaming locals.
- `moved` and `import` (lab 22) are complementary: import adopts *unknown* resources,
  moved reconciles *known* state addresses.