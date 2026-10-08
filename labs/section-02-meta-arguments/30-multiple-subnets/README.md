# Lab 30 — Multiple subnets with `for_each`

Build several subnets from a map. This is the pattern you'll reuse for every
multi-tier network in later sections.

## What it creates

| Terraform resource           | Azure name                          | Notes                                    |
| ---------------------------- | ----------------------------------- | ---------------------------------------- |
| `azurerm_resource_group.this`| Resource group `rg-multi-subnets`   | 1                                        |
| `azurerm_virtual_network.this`| VNet `vnet-multi-subnets`          | 1, address space `10.150.0.0/16`         |
| `azurerm_subnet.this`        | Subnets `snet-web`, `snet-app`, `snet-data`, `snet-mgmt` | **x4 via `for_each` over a map** |

## Commands

```bash
cd 30-multiple-subnets
terraform init
terraform plan
terraform apply
terraform output subnet_ids
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-multi-subnets` → VNet `vnet-multi-subnets` → **Subnets**:
  four subnets, each with the `/24` CIDR from the `subnets` map
  (`web=10.150.1.0/24`, `app=10.150.2.0/24`, `data=10.150.3.0/24`, `mgmt=10.150.4.0/24`).
- `terraform output subnet_ids` prints a map of subnet name → full Azure resource ID.

## Key concepts / gotchas

- `each.key` = the tier name (used in the subnet name), `each.value` = the CIDR.
  One block of code describes all four tiers.
- Subnets must fit inside the VNet's address space; overlapping or too-wide prefixes
  fail at apply time with an Azure error.
- The output uses a **for expression** `{ for k, s in azurerm_subnet.this : k => s.id }`
  to turn the for_each map of instances into a clean key → id map.
- Add a new entry to the map (e.g. `cache = "10.150.5.0/24"`) and rerun: only the new
  subnet is created — no other subnet is touched, which is the `for_each` advantage
  over `count`.
