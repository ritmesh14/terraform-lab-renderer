# Lab 73 — Modules — building an Azure resource group

Start small: a module that creates **only** a resource group. This lab shows the module
contract (variables + resource + output) and how a caller consumes it. A module is just a
folder of `.tf` files; the root config points at it with `source`, passes inputs in the
block body, and reads results back with `module.<name>.<output>`.

The module itself lives at `labs/modules/rg-only/` (shared with other sections).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `module "rg"` (source `../../modules/rg-only`) | `rg-modulerg` | One resource group; the module wraps `azurerm_resource_group` |
| `azurerm_resource_group` (inside the module) | rg-modulerg | Created once, reused by every caller |

## Commands

Prerequisite: `az login` (Terraform uses your CLI login's subscription).

```bash
cd labs/section-04-modules-and-networking/73-module-resource-group
terraform init     # also copies/links the local module into .terraform/
terraform plan     # shows 1 resource to add — the module's resource group
terraform apply    # type yes
terraform output   # rg_id, rg_name
terraform destroy  # clean up
```

No `terraform.tfvars` needed — this lab has no input variables.

## What to see in the Azure portal

- Resource group **rg-modulerg** in **East US** — empty (a resource group holds nothing yet).
- Under **Settings → Deployments** you can see Terraform's deployment activity.

## Key concepts / gotchas

- **Module contract** = the module's `variable` blocks (inputs) + `output` blocks
  (outputs). Callers only ever touch the contract, never the module's internals.
- `source = "../../modules/rg-only"` is a *local path* module. It is copied into
  `.terraform/modules/` at `init`; changes to the module are picked up on the next plan.
- Outputs surface the module's results: `module.rg.id` and `module.rg.name` in the caller.
- Local-path sources are the Terraform-native way to DRY up configs; registry sources
  (lab 93) add version pinning on top.
