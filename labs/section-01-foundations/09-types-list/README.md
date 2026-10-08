# 09 — Types — List

A `list` is an ordered, index-addressed collection. This lab uses a list of subnet
prefixes and loops over it with `for` to build subnets inline. One list drives the whole
VNet: change the list, and Terraform creates or removes the matching subnets.

Concepts:

- `list(string)` type
- `length()` and `[index]` access
- a `for` expression turning a list of strings into a list of objects

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-list-foundation` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-list` | `10.50.0.0/16` |
| generated subnets | `snet-tier1`, `snet-tier2`, `snet-tier3` | `10.50.1/2/3.0/24` from the list |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/09-types-list
terraform init
terraform plan
terraform apply
terraform output subnet_names
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-list-foundation` → `vnet-list` → **Subnets**: three subnets
named `snet-tier1` to `snet-tier3` with ranges `10.50.1.0/24`, `10.50.2.0/24`,
`10.50.3.0/24` — exactly the three entries in `local.subnet_prefixes`.

## Key concepts / gotchas

- A list is **ordered** and addressed by position: `local.subnet_prefixes[0]` is
  `10.50.1.0/24`, `length(...)` returns 3.
- `[for i, p in list : ...]` gives you both index `i` and value `p` — here `i + 1`
  builds the tier number in each subnet name.
- `dynamic "subnet" { for_each = ... }` repeats a nested block once per element.
  `for_each` needs a *map or set*, so the code converts the list of objects to a map
  keyed by `s.name` first.
- Inside `dynamic`, `subnet.value` is the current element's object (`subnet.key` would
  be the map key).
- Removing an entry from the list makes Terraform remove that subnet on the next apply
  — the data structure is the single source of truth.