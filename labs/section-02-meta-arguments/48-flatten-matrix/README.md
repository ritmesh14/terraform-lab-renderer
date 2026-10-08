# Lab 48 — `flatten()` — nested structures into a resource list (advanced)

`flatten()` turns a nested list-of-lists into one flat list, which you then iterate with
`for_each`. Here a matrix of **region × tier** is expanded into a flat list of subnets —
one per (region, tier) pair — each created as its own resource in the matching regional
VNet.

Addressing: `vnet-regionA` uses `172.20.0.0/20`, `vnet-regionB` uses `172.21.0.0/20`;
subnets are `/26`.

## What it creates

| Terraform resource              | Azure name                              | Notes                                        |
| ------------------------------- | --------------------------------------- | -------------------------------------------- |
| `azurerm_resource_group.this`   | Resource group `rg-flatten`             | 1                                            |
| `azurerm_virtual_network.this`  | VNets `vnet-regionA`, `vnet-regionB`    | **x2 via `for_each` over `toset(regions)`**  |
| `azurerm_subnet.this`           | Subnets `snet-web`, `snet-app` in each VNet | **x4 via `for_each` over the flattened matrix** |

## Commands

```bash
cd 48-flatten-matrix
terraform init
terraform plan
terraform apply
terraform output subnet_keys
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-flatten`: two VNets. Open `vnet-regionA` → **Subnets**:
  `snet-web` and `snet-app`, with `/26` prefixes carved from `172.20.0.0/20`
  (`cidrsubnet(..., 6, 0)` → `172.20.0.0/26`, index 1 → `172.20.0.64/26`); the same
  pair inside `vnet-regionB` from `172.21.0.0/20`.
- `terraform output subnet_keys` prints `regionA-web`, `regionA-app`, `regionB-web`,
  `regionB-app` — the matrix keys.

## Key concepts / gotchas

- The nested `for` builds a **list of lists**: for each region, one entry per tier,
  each carrying `{region, tier, cidr}`.
- `flatten()` collapses the nesting into a single list — the required shape for
  `for_each`, which accepts only set/map-like collections, not nested lists.
- `cidrsubnet(base, 6, i)` adds 6 bits to the prefix (`/20` → `/26`) and picks block
  number `i` — how each tier's subnet is carved from its region's space.
- The subnet `for_each` uses a map keyed by `"${s.region}-${s.tier}"`; keys must be
  unique, so the compound key is what makes every combination addressable.
- `azurerm_virtual_network.this[each.value.region].name` shows keyed lookup into
  another for_each resource — subnets land in the VNet of their own region.
- Adding a region or tier to the variables creates only the missing pairs; nothing
  else is touched.
