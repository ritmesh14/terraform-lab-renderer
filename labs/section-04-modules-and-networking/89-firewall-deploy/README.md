# Lab 89 — Azure Firewall — deployment

Create the firewall in `AzureFirewallSubnet` with a public IP for its frontend. The
firewall is a managed stateful network appliance: this lab deploys it (sku
`AZFW_VNet` / Standard) and outputs its **private IP**, which lab 90 uses as the next
hop of the default route and lab 91 DNATs SSH through its public IP.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-fw-deploy` | eastus |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-hub-fw-deploy` / `AzureFirewallSubnet` | 10.29.0.0/16, subnet 10.29.0.0/26 |
| `azurerm_public_ip` | `pip-fw` | Static / Standard |
| `azurerm_firewall` | `fw-app1-hub` | AZFW_VNet, Standard tier |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/89-firewall-deploy
terraform init
terraform plan    # 5 resources to add — note the firewall takes ~5 minutes to deploy
terraform apply
terraform output  # firewall_private_ip, firewall_id
terraform destroy
```

No `terraform.tfvars` needed.

## What to see in the Azure portal

- Resource group **rg-fw-deploy** → **fw-app1-hub → Overview**: both the **public IP**
  (pip-fw) and the **private IP** (10.29.0.x) of the firewall.
- **fw-app1-hub → Firewall policies / Rules**: none yet — this firewall is deployed
  bare; labs 90-92 attach routing and rules.
- Provisioning shows "Succeeded" only after several minutes — a normal apply is slow here.

## Key concepts / gotchas

- `sku_name = "AZFW_VNet"` means the firewall is deployed inside this VNet (vs
  `AZFW_Hub` for Virtual WAN hubs); `sku_tier = "Standard"` unlocks NAT + network +
  application rules.
- **One `ip_configuration` = one AzureFirewallSubnet + one public IP**, and that's
  where the firewall's private IP comes from — the output reads
  `ip_configuration[0].private_ip_address`.
- The firewall has no rules yet: it is reachable (has a public IP) but passes nothing
  meaningful until NAT/network/application rules exist.
- The private IP is the anchor for routing: in lab 90 it becomes the next hop of a UDR
  pointed at `0.0.0.0/0`.
