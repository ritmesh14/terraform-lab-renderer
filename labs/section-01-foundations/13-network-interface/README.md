# 13 — Network interface

A VM needs a NIC. This lab creates the VNet + web subnet, then an
`azurerm_network_interface` with one `ip_configuration` bound to that subnet. A NIC can
carry several IP configurations (this one has just one, private, dynamic).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-nic-foundation` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-nic` | `10.90.0.0/16` |
| `azurerm_subnet.web` | `snet-web` | `10.90.1.0/24` |
| `azurerm_network_interface.web` | `nic-web-01` | One `ip_configuration`, dynamic private IP |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/13-network-interface
terraform init
terraform plan
terraform apply
terraform output nic_private_ip
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-nic-foundation` → `nic-web-01` → **Overview**. Verify:
- **IP address**: a private IP inside `10.90.1.0/24` (e.g. `10.90.1.4`) — allocation
  method *Dynamic*.
- **Subnet/virtual network**: `snet-web` / `vnet-nic`.
- There is **no** public IP attached — that comes in lab 15.

## Key concepts / gotchas

- A **NIC is the network card** of a future VM: it is what actually lives in a subnet
  and owns the IP addresses. `subnet_id = azurerm_subnet.web.id` is the full resource
  *id*, not just the name.
- `private_ip_address_allocation = "Dynamic"` means Azure picks any free IP from the
  subnet — the value can change if the NIC is recreated. `Static` pins it.
- `ip_configuration` is a nested block; a NIC supports several, and this lab's
  assignment is to add a second one with a static private IP.
- The dependency chain is fully implicit here: NIC → subnet → VNet → RG, and Terraform
  creates them in exactly that order.
- `private_ip_address` is only known *after* Azure assigns it, so it is a computed
  attribute — that is why it is exposed as an output rather than chosen in code.