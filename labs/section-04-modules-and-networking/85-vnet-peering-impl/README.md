# Lab 85 — VNet peering — implementation

Add bidirectional peering with `azurerm_virtual_network_peering`. Both directions are
needed (hub→spoke and spoke→hub). Enable `allow_virtual_network_access` so traffic flows;
`allow_forwarded_traffic` lets the hub route for the spoke. Both VNets are self-contained
in this lab's resource group for simplicity — the peering relationship is what matters.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-peer-impl` | eastus |
| `azurerm_virtual_network` | `vnet-impl-hub` | 10.24.0.0/16 |
| `azurerm_virtual_network` | `vnet-impl-spoke` | 10.25.0.0/16 |
| `azurerm_virtual_network_peering` | `hub-to-spoke` | On the hub, → spoke |
| `azurerm_virtual_network_peering` | `spoke-to-hub` | On the spoke, → hub |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/85-vnet-peering-impl
terraform init
terraform plan    # 5 resources to add
terraform apply
terraform output  # hub_id, spoke_id
terraform destroy
```

No `terraform.tfvars` needed. Pair with lab 84's VMs for a live ping test across the
peerings (or add a VM to one of these VNets yourself).

## What to see in the Azure portal

- **vnet-impl-hub → Peerings**: `hub-to-spoke` with status **Connected** on both the
  local and remote side (peering is only "Connected" once the remote side exists).
- Same for **vnet-impl-spoke → Peerings**: `spoke-to-hub`.
- With a VM in each VNet: `ping <spoke_private_ip>` from the hub VM now succeeds.

## Key concepts / gotchas

- **Peering is NOT one resource — you need BOTH directions.** A one-way peering shows
  "Connected (local only)" and traffic still fails.
- Non-overlapping address spaces are a hard requirement (10.24/16 vs 10.25/16 here).
- `allow_virtual_network_access` is what actually permits traffic between the VNets
  (default true in this resource); `allow_forwarded_traffic` is for traffic *relayed*
  through the peer (e.g. hub routing for the spoke) — it is not needed for direct VM-to-VM.
- Gateway transit (`allow_gateway_transit` / `use_remote_gateways`) is the other common
  pair of flags — not used here, but that's how a spoke reaches on-prem via a hub VPN.
- Peering is private and free of transit through the internet; bandwidth is unmetered
  within the Microsoft backbone (cross-region data transfer is billed).
