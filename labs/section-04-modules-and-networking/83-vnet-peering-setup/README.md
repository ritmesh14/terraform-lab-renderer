# Lab 83 — VNet peering — setup

Create two VNets in different regions, each with a subnet. Lab 85 peers them; this lab
is deliberately the "before" picture — two completely disconnected networks in separate
resource groups and separate regions.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-hub` | eastus |
| `azurerm_virtual_network` | `vnet-hub` | 10.20.0.0/16 |
| `azurerm_subnet` | `vnet-hub/snet-hub` | 10.20.1.0/24 |
| `azurerm_resource_group` | `rg-spoke` | westus2 |
| `azurerm_virtual_network` | `vnet-spoke` | 10.21.0.0/16 |
| `azurerm_subnet` | `vnet-spoke/snet-spoke` | 10.21.1.0/24 |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/83-vnet-peering-setup
terraform init
terraform plan    # 6 resources to add
terraform apply
terraform output  # hub_id, spoke_id
terraform destroy
```

No `terraform.tfvars` needed.

## What to see in the Azure portal

- Resource groups **rg-hub** (East US) and **rg-spoke** (West US 2).
- **vnet-hub → Subnets**: `snet-hub` 10.20.1.0/24. Same for the spoke.
- **vnet-hub → Peerings**: empty — nothing is peered yet (that's lab 85).

## Key concepts / gotchas

- **Address spaces must not overlap** for peering to be possible: 10.20/16 vs 10.21/16.
- Peering is configured on the VNet resource, so this lab only builds the two VNets and
  their ids as outputs — the "contract" lab 85's peering resources need.
- Cross-region peering works (region of the VNets is irrelevant to the peering itself),
  and traffic across peering uses Microsoft's backbone, not the public internet.
- Two separate resource groups here on purpose: peering works across resource groups
  (and even subscriptions), not just within one.
