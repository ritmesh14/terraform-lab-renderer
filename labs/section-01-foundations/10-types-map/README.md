# 10 — Types — Map

A `map` is a key→value collection. Maps are ideal when you address things by a
meaningful key rather than a positional index. Here each subnet has a key (`web`,
`app`, `data`) carrying its role, and `for_each` turns that map into three subnets.

Concepts:

- `map(object({...}))` type
- `for_each` over a map
- `each.key` / `each.value`

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-map-foundation` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-map` | `10.60.0.0/16` |
| `azurerm_subnet.this` (x3 via `for_each`) | `snet-web`, `snet-app`, `snet-data` | One per map key, prefixes from `each.value.prefix` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/10-types-map
terraform init
terraform plan
terraform apply
terraform output subnet_ids
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-map-foundation` → `vnet-map` → **Subnets**: three subnets
named by role — `snet-web` (10.60.1.0/24), `snet-app` (10.60.2.0/24), `snet-data`
(10.60.3.0/24) — straight from the `subnets` map in `locals`.

## Key concepts / gotchas

- **Map keys are stable identities.** Add a `cache = {...}` entry to the map and
  Terraform creates one new subnet; the existing ones are untouched. With a list
  (lab 09), inserting in the middle shifts every index and can churn resources.
- Inside `for_each`, `each.key` is `"web"` etc. and `each.value` is the whole object,
  so `each.value.prefix` reads like `subnets["web"].prefix`.
- `each.value.nsg` is declared in the map but not used in this lab — the
  `map(object)` shape is exactly what lab 11 turns into a typed input variable.
- The `subnet_ids` output uses a `for` expression over the resource map itself to
  produce a map of name → id.
- `for_each` requires a map or a set of strings — never a plain list (keys must be
  stable), which is why maps pair so naturally with it.