# Lab 93 — Using a module from the Terraform Registry

Public modules live at registry.terraform.io. This lab uses the popular
**`Azure/network/azurerm`** module to create a VNet + subnets without writing the
resources ourselves.

```hcl
module "network" {
  source  = "Azure/network/azurerm"
  version = "5.2.0"
  ...
}
```

Run `terraform init` — Terraform downloads the module and the lock file pins it.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` (inside the module) | `rg-registry-module` | Created by the registry module |
| `azurerm_virtual_network` (inside) | `acctvnet` | The module's default name — the lab doesn't override `vnet_name` |
| `azurerm_subnet` × 2 (`use_for_each = true`) | `web`, `app` | 10.33.1.0/24, 10.33.2.0/24 |

## Commands

Prerequisite: `az login`. The module is fetched over the network, so `init` needs
internet access:

```bash
cd labs/section-04-modules-and-networking/93-registry-module
terraform init     # downloads Azure/network/azurerm@5.2.0 into .terraform/
terraform plan     # 4 resources to add
terraform apply
terraform output   # vnet_id, subnet_ids
terraform destroy
```

No `terraform.tfvars` needed. Note there is **no local module folder** here —
`init` downloads the module into `.terraform/modules/network/` (its README,
`variables.tf` and `outputs.tf` are the module's documentation and contract).

## What to see in the Azure portal

- Resource group **rg-registry-module** → **acctvnet → Subnets**: `web` and `app` with
  the two /24s. (The VNet is named `acctvnet` — the registry module's default — another
  reason to read a module's docs/defaults before calling it.)
- Only the resources the module itself creates are deployed — its `examples/` folder is
  just source code you can read, not resources you get.

## Key concepts / gotchas

- **source formats differ by origin**: `Azure/network/azurerm` is a registry shorthand
  (`<namespace>/<name>/<provider>`, no path, no URL). Compare with the local paths
  (`../../modules/vnet`) used in labs 73-78.
- **Pin `version`** — without it `init` grabs the newest release and a major upgrade can
  break your plan. `.terraform.lock.hcl` then records the exact chosen version so every
  run is reproducible.
- **Read the module's docs before calling it**: input and output names are the module
  author's choice (`vnet_subnets`, not `subnet_ids`; `resource_group_location`, not
  `location`). The docs page on registry.terraform.io is the contract.
- `use_for_each = true` is an input *offered by the module* to switch its subnets from
  `count` to `for_each` — version 5.2.0 defaults to `false`, which makes the number of
  subnets immutable. Community modules often expose such toggles.
- A registry module brings its own provider requirements, but your root config must
  still declare and configure the azurerm provider (see `terraform.tf`).
