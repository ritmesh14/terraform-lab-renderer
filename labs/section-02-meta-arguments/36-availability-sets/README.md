# Lab 36 — Availability Sets

An Availability Set spreads VMs across fault domains (hardware) and update domains
(patch waves) within a single datacenter — with VMs spread across 2+ fault domains
and 2+ update domains, Microsoft's SLA for that VM pair goes up to 99.95% (no zones
involved). Two VMs reference the same availability set id.

## What it creates

| Terraform resource                  | Azure name                   | Notes                                        |
| ----------------------------------- | ---------------------------- | -------------------------------------------- |
| `azurerm_resource_group.this`       | Resource group `rg-availset` | 1                                            |
| `azurerm_availability_set.web`      | Availability set `as-web`    | 1, 2 fault domains / 5 update domains        |
| `azurerm_virtual_network.this`      | VNet `vnet-availset`         | 1, `10.200.0.0/16`                           |
| `azurerm_subnet.web`                | Subnet `snet-web`            | 1, `10.200.1.0/24`                           |
| `azurerm_network_interface.web`     | NICs `nic-as-0`, `nic-as-1`  | **x2 via `count`**                           |
| `azurerm_linux_virtual_machine.web` | VMs `vm-as-0`, `vm-as-1`     | **x2 via `count`**, both join `as-web`       |

## Commands

```bash
cd 36-availability-sets
terraform init
terraform plan
terraform apply -var=admin_ssh_key="ssh-rsa AAAA... your@email"
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-availset` → availability set `as-web` → **Machines**:
  both VMs `vm-as-0` and `vm-as-1` listed; note the **fault domain** /
  **update domain** columns — Azure placed them on different hardware.
- Each VM is attached to its own `nic-as-N` in `snet-web`.

## Key concepts / gotchas

- `availability_set_id` is the only link: both counted VMs reference the SAME set id,
  and Azure then guarantees they land in different fault/update domains.
- Fault domains = separate power/network hardware (rack level); update domains =
  which VMs reboot together during maintenance.
- An availability set is a property you must set **at creation** — moving an existing
  VM into a set means recreating the VM.
- Count-pairing again: `network_interface_ids` uses `[count.index]` so VM[i] gets
  NIC[i].
- Availability sets protect within one datacenter; across datacenters you need
  Availability Zones (lab 37).
