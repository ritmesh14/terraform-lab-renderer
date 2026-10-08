# Lab 74 — Modules — building the virtual network

Extend the idea: a module that creates a resource group + VNet + subnets. The caller
passes the address space and a pair of parallel lists (subnet names and CIDRs), and the
module turns them into one subnet per entry with `for_each` over a `zipmap`.

The module lives at `labs/modules/vnet/`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` (in module) | `rg-vnet-modvnet` | Named `rg-<name>` by the module |
| `azurerm_virtual_network` (in module) | `vnet-modvnet` | Address space 10.11.0.0/16 |
| `azurerm_subnet` × 2 (`for_each`) | `vnet-modvnet/web`, `vnet-modvnet/app` | 10.11.1.0/24 and 10.11.2.0/24 |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/74-module-vnet
terraform init
terraform plan    # 4 resources to add
terraform apply
terraform output  # vnet_id, subnet_ids
terraform destroy
```

No `terraform.tfvars` needed.

## What to see in the Azure portal

- Resource group **rg-vnet-modvnet** → **vnet-modvnet** → **Subnets**: you should see
  `web` (10.11.1.0/24) and `app` (10.11.2.0/24).

## Key concepts / gotchas

- **Parallel lists in, resources out**: the caller passes `subnet_prefixes` and
  `subnet_names`; the module zips them (`zipmap(names, prefixes)`) and creates a subnet
  per pair with `for_each`.
- Outputs: `module.network.vnet_id` (string) and `module.network.subnet_ids` (list) — the
  shapes are part of the contract; later labs consume `subnet_ids[0]`.
- The module creates its own resource group, so callers don't need to pass one in —
  convenient here, but check the contract before assuming a module manages its RG.
- Changing the number/order of subnets rewrites the `for_each` keys, which can force
  subnet replacement — a good reason modules like lab 93's offer a `use_for_each` toggle.
