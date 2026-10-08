# Lab 50 — Dynamic blocks at multiple levels (advanced)

Combine two `dynamic` blocks in one resource: an NSG whose **security rules** are
generated from a list, and a NIC whose **ip_configurations** are generated from a list —
all from variables, no code changes to add a rule or an IP config.

Addressing: VNet `172.22.0.0/20`, subnet `172.22.0.0/26`.

## What it creates

| Terraform resource                    | Azure name                    | Notes                                                 |
| ------------------------------------- | ----------------------------- | ----------------------------------------------------- |
| `azurerm_resource_group.this`         | Resource group `rg-dynamic-multi` | 1                                                 |
| `azurerm_virtual_network.this`        | VNet `vnet-dynamic-multi`     | 1, `172.22.0.0/20`                                    |
| `azurerm_subnet.web`                  | Subnet `snet-web`             | 1, `172.22.0.0/26`                                    |
| `azurerm_network_security_group.web`  | NSG `nsg-dynamic-multi`       | **x2 `security_rule` blocks via `dynamic`**           |
| `azurerm_network_interface.web`       | NIC `nic-dynamic-multi`       | **x2 `ip_configuration` blocks via `dynamic`**, 2 static IPs |

## Commands

```bash
cd 50-dynamic-multi
terraform init
terraform plan
terraform apply
terraform output nic_ips
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-dynamic-multi` → NSG `nsg-dynamic-multi` → **Inbound security
  rules**: `Allow-SSH` (22) and `Allow-HTTPS` (443), from the `rules` variable.
- NIC `nic-dynamic-multi` → **IP configurations**: two static IPs, `172.22.0.10`
  (primary) and `172.22.0.11` — one per entry of the `ip_configs` variable.
- `terraform output nic_ips` prints both addresses.

## Key concepts / gotchas

- Two independent `dynamic` blocks in one configuration — the pattern scales to any
  repeatable nested block (rules, IP configs, data disks, origins, backends…).
- The iterator name comes from the block label (`security_rule.value`,
  `ip_configuration.value`), not `each.value` — a classic source of confusion.
- `Static` allocation + explicit `private_ip_address` per config shows multi-IP NICs;
  exactly one config must have `primary = true`.
- The `nic_ips` output reads `private_ip_addresses`, a provider-computed list, so you
  can verify the fan-out without opening the portal.
- Dynamic blocks trade readability for flexibility — past a handful of fields or a
  small fixed set, plain nested blocks are easier to debug.
