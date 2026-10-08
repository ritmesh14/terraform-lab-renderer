# Lab 91 — Azure Firewall — NAT rule

A DNAT rule forwards inbound port 22 on the firewall's public IP to the workload VM's
port 22, so you can SSH to the workload *through* the firewall without a public IP on
the VM. This lab is self-contained: it builds its own firewall + `AzureFirewallSubnet`
+ public IP and then adds the NAT rule collection.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-fw-nat` | eastus |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-hub-fw-nat` / `AzureFirewallSubnet` | 10.31.0.0/16, subnet 10.31.0.0/26 |
| `azurerm_public_ip` | `pip-fw-nat` | The address you SSH to |
| `azurerm_firewall` | `fw-app1-nat` | AZFW_VNet, Standard |
| `azurerm_firewall_nat_rule_collection` | `nat-ssh` | Action **Dnat**, priority 100 |

## Commands

Prerequisite: `az login`. Needs the workload VM's private IP as input (the address the
rule translates to — e.g. lab 88's `vm-fw-workload`, or any target VM):

```bash
cd labs/section-04-modules-and-networking/91-firewall-nat-rule
cp terraform.tfvars.example terraform.tfvars   # then fill in workload_private_ip = "10.28.1.x"
terraform init
terraform plan    # 6 resources to add
terraform apply
terraform output  # fw_public_ip
ssh azureadmin@<fw_public_ip>   # lands on the workload VM, via the firewall
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-fw-nat** → **fw-app1-nat → NAT rules**: collection `nat-ssh`
  containing `ssh-to-workload` — source `*`, destination port 22 on the firewall's
  public IP, translated to `<workload_private_ip>:22`, protocol TCP.
- **pip-fw-nat**: the public address to connect to.
- SSH from your machine to `<fw_public_ip>`: the firewall rewrites the destination and
  forwards to the VM's private 10.x address — the VM never had a public IP.

## Key concepts / gotchas

- **DNAT = destination NAT = port forwarding**: inbound on the firewall's public IP is
  translated to a private IP/port behind it. Network/application rules are for *egress*;
  NAT rules are for *ingress*.
- `destination_addresses` is the **public IP** (what the client connects to) and
  `translated_address`/`translated_port` the private target — easy to mix up.
- In azurerm 3.x rule collections are separate resources
  (`azurerm_firewall_nat_rule_collection` referencing `azure_firewall_name`), not nested
  blocks on the firewall.
- NAT rule collections are matched before network rules — DNAT'ed traffic still needs an
  allow path (the DNAT itself permits the flow).
