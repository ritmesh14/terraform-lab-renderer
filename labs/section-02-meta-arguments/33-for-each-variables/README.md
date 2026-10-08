# Lab 33 — `for_each` with variables

Combine `for_each` with a typed `map` variable. This is the production pattern: the same
code deploys different shapes per environment just by changing tfvars.

## What it creates

| Terraform resource                 | Azure name                          | Notes                                                 |
| ---------------------------------- | ----------------------------------- | ----------------------------------------------------- |
| `azurerm_resource_group.this`      | Resource group `rg-foreach-vars`    | 1                                                     |
| `azurerm_virtual_network.this`     | VNet `vnet-foreach-vars`            | 1, address space `10.170.0.0/16`                      |
| `azurerm_subnet.this`              | Subnets `snet-<each key>`           | **x N via `for_each = var.subnets`** (one per variable entry) |
| `azurerm_network_security_group.this` | NSGs `nsg-<tier>`                | **only for entries with `nsg = true`** (filtered `for`) |

The default variable value is set in your `terraform.tfvars` / `-var` — pass e.g.
`web={prefix="10.170.1.0/24",nsg=true}` style entries. Without a value Terraform
prompts for it.

## Commands

```bash
cd 33-for-each-variables
terraform init
terraform plan
terraform apply
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-foreach-vars` → VNet `vnet-foreach-vars` → **Subnets**: one
  subnet per entry of the variable map, each with the CIDR you passed.
- The same resource group also shows the NSGs — only for the tiers flagged
  `nsg = true`; tiers with `nsg = false` have a subnet but **no** NSG.

## Key concepts / gotchas

- `map(object({prefix = string, nsg = bool}))` is a **typed** variable: Terraform
  rejects entries missing `prefix` or with `nsg = "yes"` instead of a bool.
- The subnet block iterates the variable directly; `each.value.prefix` reaches into
  the object.
- The NSG block uses a **filtered for expression**:
  `{ for k, v in var.subnets : k => v if v.nsg }` — the `if` drops non-matching
  entries, so `nsg = false` tiers get no NSG at all.
- Changing one entry in tfvars and re-applying changes only that subnet/NSG.
- Same code, different inputs = the whole point of variables plus `for_each`.
