# Lab 92 — Azure Firewall — application rule

Application rules are Layer-7 (FQDN) allow rules. This one lets a subnet reach
`*.ubuntu.com` and `github.com` for apt/package downloads while denying other internet.
The lab is self-contained: firewall + `AzureFirewallSubnet` + public IP + the
application rule collection.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-fw-app` | eastus |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-hub-fw-app` / `AzureFirewallSubnet` | 10.32.0.0/16, subnet 10.32.0.0/26 |
| `azurerm_public_ip` | `pip-fw-app` | Firewall's public/SNAT IP |
| `azurerm_firewall` | `fw-app1-app` | AZFW_VNet, Standard |
| `azurerm_firewall_application_rule_collection` | `app-allow` | Action Allow, priority 100 |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/92-firewall-app-rule
terraform init
terraform plan    # 6 resources to add
terraform apply
terraform output  # fw_public_ip
terraform destroy
```

No `terraform.tfvars` needed.

## What to see in the Azure portal

- Resource group **rg-fw-app** → **fw-app1-app → Application rules**: collection
  `app-allow` → rule `allow-updates` — source `10.32.1.0/24`, protocols HTTP:80 and
  HTTPS:443, target FQDNs `*.ubuntu.com`, `github.com`, `*.githubusercontent.com`.
- End-to-end behaviour (with lab 90-style routing to this firewall): from a VM in
  10.32.1.0/24, `apt update` / `git clone` succeed, but `curl https://example.com`
  times out — egress is restricted to the allowed FQDNs.

## Key concepts / gotchas

- **Application rules filter by FQDN, not just IP**: the firewall resolves the hostname
  on the fly (TLS SNI/HTTP host header), which is how egress control usually works.
- `source_addresses` is the *client* range (the protected subnet) — here
  `10.32.1.0/24`; anything outside it isn't matched by this rule.
- Wildcards are FQDN-style: `*.ubuntu.com` covers `archive.ubuntu.com` etc. One
  `protocol` block per protocol/port pair; HTTP/HTTPS ports here are explicit.
- Everything not allowed by a rule is **denied by default** — that implicit deny is the
  whole point of a firewall.
- Egress must actually be *routed* to the firewall (lab 90's UDR) for these rules to
  see the traffic; the rule alone changes nothing.
