# Lab 31 — Multiple network interfaces (assignment)

Self-check: create one NIC per tier in the VNet from lab 30. Each NIC lives in the
matching subnet, keyed by the same map.

## What it creates

| Terraform resource                  | Azure name                        | Notes                                              |
| ----------------------------------- | --------------------------------- | -------------------------------------------------- |
| `azurerm_resource_group.this`       | Resource group `rg-multi-nics`    | 1                                                  |
| `azurerm_virtual_network.this`      | VNet `vnet-multi-nics`            | 1, address space `10.160.0.0/16`                   |
| `azurerm_subnet.this`               | Subnets `snet-web`, `snet-app`, `snet-data` | **x3 via `for_each` over a computed map** |
| `azurerm_network_interface.this`    | NICs `nic-web`, `nic-app`, `nic-data` | **x3 via `for_each` over the subnet map**      |

## Commands

```bash
cd 31-multiple-nics
terraform init
terraform plan
terraform apply
terraform output nics
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-multi-nics` → VNet `vnet-multi-nics` → **Subnets**: three subnets
  `10.160.1.0/24`, `10.160.2.0/24`, `10.160.3.0/24`, each with one attached NIC
  (`nic-web` in `snet-web`, and so on) — click a subnet and look at
  **Connected devices**.

## Key concepts / gotchas

- A two-value `for` over a **list** gives `i` as the numeric index, used here to
  compute each tier's CIDR (`"10.160.${i + 1}.0/24"` — the first tier is `10.160.1.0/24`).
- `for_each` can iterate **another resource's map**: `for_each = azurerm_subnet.this`
  creates one NIC per subnet with matching keys, so NICs and subnets stay in sync.
- `each.value` is then a full subnet resource **object**, and `each.value.id` is the
  subnet's Azure resource ID.
- Keys must be unique and the collection may not change keys during apply — that is
  why a `toset()`/map key, not a changing list, is the usual source.
- One NIC per tier mirrors the real pattern of separating web/app/data traffic.
