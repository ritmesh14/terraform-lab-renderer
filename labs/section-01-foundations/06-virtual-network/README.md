# 06 — Virtual Network

Create an Azure Virtual Network with two subnets in one block. This lab introduces
networking — the backbone of almost every later lab — and the idea of CIDR blocks:
`10.20.0.0/16` is your private IP space, and each subnet carves a `/24` slice out of it.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-vnet-foundation` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-foundation` | Address space `10.20.0.0/16` |
| inline `subnet "snet-web"` | `snet-web` | `10.20.1.0/24` |
| inline `subnet "snet-app"` | `snet-app` | `10.20.2.0/24` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/06-virtual-network
terraform init
terraform plan
terraform apply
terraform output vnet_id
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-vnet-foundation` → `vnet-foundation` → **Subnets**. You
should see two subnets, `snet-web` with address range `10.20.1.0/24` and `snet-app`
with `10.20.2.0/24`, carved out of the VNet's `10.20.0.0/16` space.

## Key concepts / gotchas

- A VNet is **your private IP space inside Azure**; `address_space` is a *list* of CIDR
  blocks (you can add more, e.g. after peering).
- The two subnets are defined **inline** inside the `azurerm_virtual_network` resource.
  Lab 12 shows the more flexible "subnet as a separate resource" pattern.
- Subnet prefixes must sit inside the VNet's address space — `10.30.1.0/24` would fail.
- `/16` ≈ 65,000 addresses; `/24` ≈ 251 usable ones (Azure reserves 5 per subnet).