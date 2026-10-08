# Lab 75 — Modules — public IP and network interface

A module that, given an existing subnet, creates a public IP + NIC. Shows how a module
consumes a resource id produced upstream (subnet from the vnet module) — modules chain
together: one module's **output** becomes the next module's **input**.

Modules used: `labs/modules/vnet` (network) and `labs/modules/ip-nic` (IP + NIC).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `module "network"` (vnet module) | `rg-vnet-modip`, `vnet-modip`, subnet `web` | 10.12.0.0/16, 10.12.1.0/24 |
| `module "nic"` (ip-nic module) | `pip-nic-modip` | Static, Standard SKU public IP |
| `azurerm_network_interface` (in nic module) | `nic-modip` | Dynamic private IP in subnet `web` |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/75-module-ip-nic
terraform init
terraform plan    # 5 resources to add (rg, vnet, subnet, public IP, NIC)
terraform apply
terraform output  # nic_id, public_ip
terraform destroy
```

No `terraform.tfvars` needed. Note the caller hardcodes `resource_group_name =
"rg-vnet-modip"` — it must match the name the vnet module generates (`rg-<name>`).

## What to see in the Azure portal

- Resource group **rg-vnet-modip** → **vnet-modip → Subnets → web → Connected devices**:
  `nic-modip` with a dynamic private IP (10.12.1.x).
- **pip-nic-modip** under Public IP addresses: SKU **Standard**, allocation **Static**,
  and an actual IP address assigned.

## Key concepts / gotchas

- **Module chaining**: `subnet_id = module.network.subnet_ids[0]` — a module output is
  wired straight into the next module's input. Terraform infers the dependency order
  automatically (no `depends_on` needed).
- The nic module deliberately does *not* create a subnet: it takes `subnet_id` as an
  input. Modules should own what they create and accept ids for what already exists.
- `subnet_ids[0]` indexes a list output — order follows the module's output expression.
- The public IP is separate from the NIC (`ip_configuration.public_ip_address_id`) and
  only "attaches" when referenced by the NIC.
