# Lab 47 — Conditional resources (advanced feature flags)

`count = var.enabled ? 1 : 0` toggles a resource on/off without an `if` block. This lab
creates a VNet always, but creates the NSG only when `deploy_nsg = true`. Flip the
variable and `terraform plan` shows the NSG being added or removed — the VNet is untouched.

Addressing: VNet `172.19.0.0/20`, subnet `172.19.0.0/26`.

## What it creates

| Terraform resource                                  | Azure name                   | Notes                                       |
| --------------------------------------------------- | ---------------------------- | ------------------------------------------- |
| `azurerm_resource_group.this`                       | Resource group `rg-conditional` | 1                                        |
| `azurerm_virtual_network.this`                      | VNet `vnet-conditional`      | 1, `172.19.0.0/20`                          |
| `azurerm_subnet.web`                                | Subnet `snet-web`            | 1, `172.19.0.0/26`                          |
| `azurerm_network_security_group.web`                | NSG `nsg-conditional`        | **only if `deploy_nsg = true`** (default)   |
| `azurerm_subnet_network_security_group_association.web` | (association)            | **same flag** — flags must match            |

## Commands

```bash
cd 47-conditional-resources
terraform init
terraform plan
terraform apply                            # NSG created (flag defaults true)
terraform apply -var=deploy_nsg=false      # plan now DESTROYS the NSG
terraform output nsg_created
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-conditional`: with the default flag you see NSG
  `nsg-conditional`, and `snet-web` shows it attached (via the association).
- Apply with `-var=deploy_nsg=false` and refresh: the NSG and the association are
  gone; the VNet, subnet and resource group remain.

## Key concepts / gotchas

- Terraform has no `if` statement — `count = var.deploy_nsg ? 1 : 0` is the idiomatic
  feature flag. `0` means the resource exists nowhere in Azure.
- Because `count` makes the resource a list, the single instance is addressed
  `azurerm_network_security_group.web[0]` — the association needs that `[0]`.
- Every dependent resource needs the SAME flag; here the association is also
  conditional, otherwise it would reference a nonexistent instance and fail.
- Flipping the flag off does not taint anything: `plan` simply shows 1 to destroy.
- The `/20` + `/26` CIDRs show block sizes can be anything that nests; /16+/24 was
  convention, not a rule.
