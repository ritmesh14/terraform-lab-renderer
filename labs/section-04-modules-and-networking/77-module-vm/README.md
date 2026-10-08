# Lab 77 — Modules — virtual machines

Consume the full `vm-stack` module that combines everything from labs 73-76 into one
reusable unit. One `module` block stands up the entire stack: RG + VNet + subnet + NSG
+ public IP + NIC + VM. The caller only passes a name prefix, region, network CIDRs, a
tags map and one secret (the SSH key).

Module: `labs/modules/vm-stack`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` (module) | `rg-modvm` | |
| `azurerm_virtual_network` (module) | `vnet-modvm` | 10.14.0.0/16 |
| `azurerm_subnet` (module) | `subnet-modvm` | 10.14.1.0/24 |
| `azurerm_network_security_group` (module) | `nsg-modvm` | Allow inbound TCP 22 |
| `azurerm_subnet_network_security_group_association` (module) | — | NSG on the subnet |
| `azurerm_public_ip` (module) | `pip-modvm` | Static / Standard |
| `azurerm_network_interface` (module) | `nic-modvm` | Private IP + the public IP attached |
| `azurerm_linux_virtual_machine` (module) | `vm-modvm` | Standard_B2s, Ubuntu 22.04 |

## Commands

Prerequisite: `az login`. This lab needs your SSH public key, so copy the example
tfvars first:

```bash
cd labs/section-04-modules-and-networking/77-module-vm
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 8 resources to add
terraform apply
terraform output  # public_ip, vm_name
terraform destroy
```

(If the tfvars example is absent, create `terraform.tfvars` with
`admin_ssh_key = "ssh-rsa AAAA... your@email"`.)

## What to see in the Azure portal

- Resource group **rg-modvm** — 8 named resources, every name built from `modvm`.
- **vm-modvm → Overview**: state Running; **Connect → SSH** using the public IP from
  `terraform output public_ip`, user `azureadmin`.

## Key concepts / gotchas

- **One input drives everything**: `name_prefix` alone names all 8 resources
  (`rg-`, `vnet-`, `subnet-`, `nsg-`, `pip-`, `nic-`, `vm-` prefixes inside the module).
- `variable "admin_ssh_key" { sensitive = true }` keeps the key out of CLI output, but
  it is still stored in the state file — protect your state.
- Optional inputs with defaults (`tags = {}`, `custom_data = null`) let callers pass
  just what they need — that's what makes a stack module reusable.
- The whole stack is replaceable: `terraform destroy` removes it, a changed
  `name_prefix` builds a second identical stack. This is the "environment from a
  variable" idea.
