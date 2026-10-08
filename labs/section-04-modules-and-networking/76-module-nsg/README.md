# Lab 76 — Modules — network security groups

A module that creates an NSG with a list of allowed inbound ports, then associates it
with a given subnet. Demonstrates passing a `list(number)` and looping with `dynamic`:
the *caller* passes plain data, the *module* builds one `security_rule` block per port.

Modules used: `labs/modules/vnet` + `labs/modules/nsg`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `module "network"` (vnet module) | `rg-vnet-modnsg`, `vnet-modnsg`, subnet `web` | 10.13.0.0/16, 10.13.1.0/24 |
| `azurerm_network_security_group` (nsg module) | `nsg-modnsg` | 3 inbound Allow rules: 22, 80, 443 |
| `azurerm_subnet_network_security_group_association` (nsg module) | — | Binds the NSG to subnet `web` |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/76-module-nsg
terraform init
terraform plan    # 5 resources to add
terraform apply
terraform output  # nsg_id
terraform destroy
```

No `terraform.tfvars` needed.

## What to see in the Azure portal

- Resource group **rg-vnet-modnsg** → **nsg-modnsg** → **Inbound security rules**:
  `Allow-22`, `Allow-80`, `Allow-443`, priorities 100/101/102, all TCP, source `*`.
- Subnet **web** shows the NSG under its **Network security group** setting.

## Key concepts / gotchas

- **dynamic blocks**: inside the module, `dynamic "security_rule" { for_each = ... }`
  expands a list input into N rule blocks — the module's whole value-add over raw HCL.
- Rule **priority** must be unique per NSG; the module generates 100 + index for you.
- NSG rules are stateful and port-based; application (FQDN) filtering is the firewall's
  job (labs 92/25).
- Association is a separate resource from the NSG itself — an NSG that isn't associated
  (subnet or NIC level) protects nothing.
- `destination_address_prefix = "*"` means "any address in this NSG" — fine for a lab,
  overly broad for production.
