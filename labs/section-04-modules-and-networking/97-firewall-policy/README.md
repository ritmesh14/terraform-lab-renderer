# Lab 97 — Azure Firewall — policy-based (advanced)

Labs 89-92 attached rule collections **directly** to the firewall (classic). The modern
approach is a **Firewall Policy** (`azurerm_firewall_policy`) holding rule collection
groups, which the firewall references with `firewall_policy_id`. Policies are versioned,
can be shared across firewalls, and are the only way to use premium features / Intrusion
Detection.

This lab deploys a firewall that points at a policy containing:
- a DNAT rule (inbound SSH to a workload),
- a network rule (allow outbound to a service),
- an application rule (allow a set of FQDNs).

Addressing: VNet `172.26.0.0/20`; `AzureFirewallSubnet` `172.26.0.0/26`;
workload subnet `172.26.0.64/26`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-fw-policy` | eastus |
| `azurerm_virtual_network` / subnets | `vnet-fw-policy`, `AzureFirewallSubnet`, `snet-workload` | 172.26.0.0/20, /26, /26 |
| `azurerm_public_ip` | `pip-fw-policy` | Firewall frontend |
| `azurerm_firewall_policy` | `fw-policy-app1` | SKU Standard |
| `azurerm_firewall_policy_rule_collection_group` | `rcg-app1` | priority 100, holds all 3 collections |
| `azurerm_firewall` | `fw-app1-hub` | References the policy — no rules on the firewall |

## Commands

Prerequisite: `az login`. The DNAT rule needs a target private IP (the workload subnet's
range is 172.26.0.64/26; the variable defaults to 172.26.0.70):

```bash
cd labs/section-04-modules-and-networking/97-firewall-policy
# no tfvars needed: workload_private_ip has a default (172.26.0.70) in variables.tf
terraform init
terraform plan    # 8 resources to add — the firewall takes ~5 minutes
terraform apply
terraform output  # firewall_public_ip, policy_id
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-fw-policy** → **fw-policy-app1 → Rule collection groups**:
  `rcg-app1` containing NAT (`nat-ssh`, Dnat), Network (`net-allow`, UDP/123) and
  Application (`app-allow`, FQDNs) collections.
- **fw-app1-hub → Overview**: the firewall shows **fw-policy-app1** as its associated
  policy, and no rules of its own.
- SSH to `<firewall_public_ip>` (from `terraform output firewall_public_ip`) to test
  the DNAT rule against the workload IP.

## Key concepts / gotchas

- **Classic vs policy**: labs 89-92 used `azurerm_firewall_*_rule_collection` resources
  attached to the firewall; here the same three rule types live inside ONE
  `azurerm_firewall_policy_rule_collection_group` — priorities are per collection within
  the group (200/300/400), plus the group's own priority (100).
- Syntax shifts inside the policy: `destination_address` (singular) for DNAT, and
  application rules use `destination_fqdns` with nested `protocols { ... }` blocks.
- **Policies are reusable**: one policy can be referenced by many firewalls
  (parent/child policies enable central rule inheritance) — the main reason to prefer
  this pattern at scale.
- Premium-only features (TLS inspection, IDPS) require a policy — a firewall's tier is
  Standard here; the policy sku must match.
- Everything else is the same firewall fundamentals: `AzureFirewallSubnet` by name, one
  public IP per `ip_configuration`, UDR for egress (lab 90 pattern), DNAT for ingress.
