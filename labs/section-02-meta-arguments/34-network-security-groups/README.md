# Lab 34 — Network Security Groups

Create an NSG per tier and associate each with its subnet. The `for_each` key ties the
NSG, the subnet and the association together — one entry in the `tiers` map means one
complete tier.

## What it creates

| Terraform resource                                  | Azure name             | Notes                                        |
| --------------------------------------------------- | ---------------------- | -------------------------------------------- |
| `azurerm_resource_group.this`                       | Resource group `rg-nsgs-meta` | 1                                     |
| `azurerm_virtual_network.this`                      | VNet `vnet-nsgs`       | 1, address space `10.180.0.0/16`             |
| `azurerm_subnet.this`                               | Subnets `snet-web`, `snet-app` | **x2 via `for_each` over a map**     |
| `azurerm_network_security_group.this`               | NSGs `nsg-web`, `nsg-app` | **x2 via `for_each`**, one inbound rule each |
| `azurerm_subnet_network_security_group_association.this` | (association)    | **x2**, attaches each NSG to its subnet      |

## Commands

```bash
cd 34-network-security-groups
terraform init
terraform plan
terraform apply
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-nsgs-meta` → VNet `vnet-nsgs` → **Subnets**: `snet-web` shows an
  attached **network security group** `nsg-web` (same for `snet-app`).
- Open `nsg-web` → **Inbound security rules**: rule `Allow-app` (priority 200)
  allowing TCP 443; `nsg-app` allows TCP 8080 — the port comes from the map.

## Key concepts / gotchas

- `local.tiers` is a map of **objects** (`prefix` + `port`); `each.value.port` reads a
  field of the object, so each tier's rule differs.
- `tostring(each.value.port)` converts the number to a string —
  `destination_port_range` is a string attribute, and HCL won't auto-convert.
- Keyed addressing wires the association: `azurerm_subnet.this[each.key].id` picks the
  subnet with the same tier key as the NSG. Both resources use the same `for_each`
  collection, so the keys always match.
- The association resource is separate from the subnet — adding an NSG to an existing
  subnet is a new resource, not a change to the subnet.
- Adding a third tier to the map creates its subnet, NSG, and association in one apply.
