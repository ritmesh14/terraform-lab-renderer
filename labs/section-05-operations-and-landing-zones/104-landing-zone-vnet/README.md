# Lab 104 — Landing Zone — virtual network

Hub + two spoke VNets and a hub-to-spoke peering. The data and security RGs each host a
spoke so services are isolated by RG and by network.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.net` | `rg-lz-net` | All networking in one RG |
| `azurerm_virtual_network.hub` | `vnet-lz-hub` | 10.40.0.0/16 |
| `azurerm_virtual_network.spoke_data` | `vnet-lz-data` | 10.41.0.0/16 |
| `azurerm_virtual_network.spoke_sec` | `vnet-lz-sec` | 10.42.0.0/16 |
| `azurerm_virtual_network_peering.hub_data` | `hub-to-data` | hub → data spoke |
| `azurerm_virtual_network_peering.hub_sec` | `hub-to-sec` | hub → sec spoke |
| outputs `hub_id` / `spoke_data` / `spoke_sec` | — | VNet resource IDs for later labs |

## Commands

Prerequisite: `az login`. No tfvars needed.

```bash
cd 104-landing-zone-vnet
terraform init
terraform plan
terraform apply
terraform output hub_id
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-lz-net**. Click `vnet-lz-hub` → **Peerings** (or
**Settings → Peerings** in newer portals): you'll see `hub-to-data` and `hub-to-sec`
with **Status: Connected** and **Peering status** showing traffic forwarding enabled.
Each spoke VNet shows the same peerings from the hub's side under **Remote Gateway/
Peering** columns. Check the **Address space** on each VNet: 10.40/41/42 — no overlap.

## Key concepts / gotchas

- **Hub-and-spoke** is the classic landing-zone topology: shared services live in the
  hub, workloads in spokes, and the hub is the transit point between them.
- **A peering is two objects, not one.** Each side of the connection is its own
  resource. This lab creates only the hub→spoke halves — for full connectivity you'd
  add matching spoke→hub peering resources.
- **`allow_forwarded_traffic`** lets the hub accept traffic that isn't sourced from
  the spoke VMs themselves (e.g. routed via an NVA in the hub).
- **Address spaces must not overlap** across peered VNets — that's why the three
  ranges use different second octets (40/41/42).
- Peering is private (Microsoft backbone), not transitive: spoke-to-spoke traffic
  would need routing through the hub, which is what `allow_forwarded_traffic` enables.
