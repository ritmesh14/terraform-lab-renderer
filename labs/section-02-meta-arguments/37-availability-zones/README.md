# Lab 37 — Availability Zones

Availability Zones are physically separate datacenters with independent power. A VM
pinned to a zone contributes to the 99.99% VM SLA only when you also use premium SSD
or ultra disks and span two or more zones (the exact terms live in Microsoft's SLA
page). This lab creates three VMs, one per zone, by zipping a list of zones with
`count`.

## What it creates

| Terraform resource                  | Azure name                     | Notes                                          |
| ----------------------------------- | ------------------------------ | ---------------------------------------------- |
| `azurerm_resource_group.this`       | Resource group `rg-availzones` | 1, in a zone-capable region (eastus)           |
| `azurerm_virtual_network.this`      | VNet `vnet-availzones`         | 1, `10.210.0.0/16`                             |
| `azurerm_subnet.web`                | Subnet `snet-web`              | 1, `10.210.1.0/24`                             |
| `azurerm_network_interface.web`     | NICs `nic-az-0..2`             | **x3 via `count = length(local.zones)`**       |
| `azurerm_linux_virtual_machine.web` | VMs `vm-az-1`, `vm-az-2`, `vm-az-3` | **x3**, one pinned per zone via `zone`    |

## Commands

```bash
cd 37-availability-zones
terraform init
terraform plan
terraform apply -var=admin_ssh_key="ssh-rsa AAAA... your@email"
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-availzones`: three VMs named `vm-az-1`, `vm-az-2`, `vm-az-3`.
- Click a VM → **Overview**: the **Availability zone** field shows 1 / 2 / 3
  respectively.
- All NICs live in `snet-web` (`10.210.1.0/24`).

## Key concepts / gotchas

- `local.zones = [1, 2, 3]` drives everything: `count = length(local.zones)` sizes
  the fan-out and `local.zones[count.index]` maps instance i to zone i.
- `zone = tostring(...)` — the `zone` attribute is a string in the azurerm provider,
  so the number must be converted explicitly.
- Zones vs sets: zones span **datacenters** and (with premium/ultra disks across
  2+ zones) support a 99.99% VM SLA, at no extra cost; availability sets are the
  older within-datacenter option (up to 99.95%).
- Zone must be chosen at VM creation; it cannot be changed later without recreating.
- Both VMs and NICs here are zonal resources — a zonal failure only removes one VM.
