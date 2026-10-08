# Lab 88 — Azure Firewall — virtual machine setup

Hub-spoke preparation for the firewall labs: a hub VNet containing the subnet reserved
for Azure Firewall, plus a workload VM the firewall will protect and NAT to. Lab 89
deploys the firewall; labs 90-92 add routing, NAT and application rules.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-fw` | eastus |
| `azurerm_virtual_network` | `vnet-hub-fw` | 10.28.0.0/16 |
| `azurerm_subnet` | `AzureFirewallSubnet` | 10.28.0.0/26 — name is mandatory |
| `azurerm_subnet` | `snet-workload` | 10.28.1.0/24 |
| `azurerm_network_interface` | `nic-fw-vm` | Private IP only |
| `azurerm_linux_virtual_machine` | `vm-fw-workload` | Standard_B1s, Ubuntu 22.04 |

## Commands

Prerequisite: `az login`. Needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/88-firewall-vms
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 6 resources to add
terraform apply
terraform output  # workload_subnet_id, firewall_subnet_id, vnet_id
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-fw** → **vnet-hub-fw → Subnets**: `AzureFirewallSubnet`
  (10.28.0.0/26, empty for now) and `snet-workload`.
- **vm-fw-workload → Networking**: a private 10.28.1.x address and **no public IP** —
  in the following labs all its internet traffic must go through the firewall.

## Key concepts / gotchas

- **The subnet name must be literally `AzureFirewallSubnet`** — Azure Firewall refuses
  to deploy anywhere else, and the subnet must be /26 or larger and shared with nothing.
- `snet-workload` is the "protected" segment: lab 90's route table sends its outbound
  traffic to the firewall's private IP.
- The VM is the DNAT target in lab 91 (SSH forwarded through the firewall to its
  private IP) and the egress client in lab 92.
- Outputs (`firewall_subnet_id`, `workload_subnet_id`, `vnet_id`) are the ids labs 89-92 need — again the two-config module-contract pattern.
