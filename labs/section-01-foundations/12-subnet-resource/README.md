# 12 — Subnet as a separate resource

Lab 06 defined subnets inline. This lab uses `azurerm_subnet` as its own resource, which
is far more flexible: you can add NSGs, delegations, service endpoints and peering per
subnet without rewriting the VNet.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-separes-foundation` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-separes` | `10.80.0.0/16`, no inline subnets |
| `azurerm_subnet.web` | `snet-web` | `10.80.1.0/24` |
| `azurerm_subnet.app` | `snet-app` | `10.80.2.0/24` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/12-subnet-resource
terraform init
terraform plan
terraform apply
terraform output web_subnet_id
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-separes-foundation` → `vnet-separes` → **Subnets**:
`snet-web` (10.80.1.0/24) and `snet-app` (10.80.2.0/24) appear as full Azure objects —
each has its own **Security** (NSG) and **Delegation** settings you can open, unlike
inline subnets.

## Key concepts / gotchas

- `azurerm_subnet` needs **both** `resource_group_name` and `virtual_network_name` —
  subnets are children of a VNet but live in the RG namespace.
- `address_prefixes` is a list (one entry here); a subnet must fit inside the VNet's
  address space.
- Separate subnet resources create a clean dependency chain: subnet references the VNet,
  so Terraform orders RG → VNet → subnets automatically.
- The `web_subnet_id` output is exactly what a NIC (lab 13) consumes to place a VM —
  outputs are how later configs/modules wire into this one.
- Inline vs separate is a tradeoff: inline subnets are fewer lines; separate resources
  can carry NSGs, route tables and delegations individually. Later labs use the
  separate style.