# 16 — Network Security Group

An NSG is a stateful firewall attached to a subnet or NIC. This lab creates an NSG that
allows inbound RDP (3389) and HTTPS (443) and denies everything else by default, then
associates it with the web subnet.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-nsg-foundation` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-nsg` | `10.110.0.0/16` |
| `azurerm_subnet.web` | `snet-web` | `10.110.1.0/24` |
| `azurerm_network_security_group.web` | `nsg-web` | Rules: Allow-RDP (prio 200), Allow-HTTPS (prio 300) |
| `azurerm_subnet_network_security_group_association.web` | — | Binds the NSG to `snet-web` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/16-network-security-group
terraform init
terraform plan
terraform apply
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-nsg-foundation` → `nsg-web` → **Inbound security rules**. You
should see the two custom rules (`Allow-RDP` priority 200, `Allow-HTTPS` priority 300)
plus Azure's default rules. Then open `vnet-nsg` → **Subnets** → `snet-web`: the
**Network security group** column shows `nsg-web` — that's the association resource at
work.

## Key concepts / gotchas

- Rules are evaluated by **priority** (lower number = higher priority); the first match
  wins, and Azure's implicit *DenyAllInbound* (priority 4096) catches the rest.
- NSGs are **stateful**: if traffic is allowed inbound, the response is automatically
  allowed back out.
- `source_address_prefix = "*"` allows the whole internet — fine for the lab, dangerous
  in production. The assignment is to replace `*` with your own IP (or an Azure service
  tag such as `VirtualNetwork`).
- The **association is its own resource**
  (`azurerm_subnet_network_security_group_association`), not a property of either the
  subnet or the NSG — Terraform models it separately so either side can change
  independently.
- A default NSG with no allow rules blocks all inbound traffic; that's the "deny by
  default" posture you're extending here.