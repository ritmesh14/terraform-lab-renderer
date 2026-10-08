# Lab 84 — VNet peering — machine setup

Add one VM per VNet from lab 83 so we can test connectivity after peering. Two fully
separate stacks — hub (eastus, 10.22.0.0/16) and spoke (westus2, 10.23.0.0/16) — each
with its own RG, VNet, subnet, NIC and Linux VM. The VMs have no public IPs: before
peering there is no way in from outside, which is exactly the point.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-peer-hub` | eastus |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-peer-hub` / `snet-hub` | 10.22.0.0/16, 10.22.1.0/24 |
| `azurerm_network_interface` | `nic-hub` | Dynamic private IP |
| `azurerm_linux_virtual_machine` | `vm-hub` | Standard_B1s, Ubuntu 22.04 |
| `azurerm_resource_group` | `rg-peer-spoke` | westus2 |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-peer-spoke` / `snet-spoke` | 10.23.0.0/16, 10.23.1.0/24 |
| `azurerm_network_interface` | `nic-spoke` | Dynamic private IP |
| `azurerm_linux_virtual_machine` | `vm-spoke` | Standard_B1s |

## Commands

Prerequisite: `az login`. Needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/84-vnet-peering-machines
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # ~10 resources to add
terraform apply
terraform output  # hub_private_ip, spoke_private_ip
terraform destroy
```

## What to see in the Azure portal

- Resource groups **rg-peer-hub** and **rg-peer-spoke**, each with a VNet/subnet/NIC/VM.
- **vm-hub → Networking**: a private IP like 10.22.1.x, and **no public IP**.
- Note the two VMs are in different regions — the ping test in lab 85 works cross-region.

## Key concepts / gotchas

- **No public IPs and no peering yet**: `ping` between the VMs fails right now — the
  outputs (`hub_private_ip`, `spoke_private_ip`) are what lab 85 makes reachable.
- Both stacks are the same six resources with different names/regions — a reminder that
  identical HCL + different variables = a second environment.
- Since the VMs have no public IP, you reach them after peering from another peered VM,
  or temporarily via Azure Bastion / a serial console for debugging.
- Dynamic private IPs are fine here, but note the outputs only exist *after* apply —
  they can't be predicted at plan time.
