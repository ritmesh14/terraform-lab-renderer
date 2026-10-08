# Lab 86 — Application Gateway — virtual machines

Application Gateway is a Layer-7 load balancer with WAF, cookie affinity, and path-based
routing. Lab 86 deploys two backend VMs (the pool); lab 87 builds the gateway in front.
The VMs run nginx via cloud-init and serve a page stamped with their hostname, and the
lab outputs their private IPs — exactly what lab 87's backend pool needs.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-appgw` | eastus |
| `azurerm_virtual_network` | `vnet-appgw` | 10.26.0.0/16 |
| `azurerm_subnet` | `snet-appgw` | 10.26.1.0/24 — reserved for the gateway |
| `azurerm_subnet` | `snet-backends` | 10.26.2.0/24 — the two nginx VMs |
| `azurerm_network_interface` × 2 (`count`) | `nic-appgw-be-0`, `nic-appgw-be-1` | Private IPs only |
| `azurerm_linux_virtual_machine` × 2 (`count`) | `vm-appgw-be-0`, `vm-appgw-be-1` | nginx via cloud-init |

## Commands

Prerequisite: `az login`. Needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/86-app-gateway-vms
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 8 resources to add
terraform apply
terraform output  # backend_ids, backend_ips, appgw_subnet_id, vnet_id
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-appgw** → **vnet-appgw → Subnets**: `snet-appgw` (empty) and
  `snet-backends`.
- **snet-appgw → Connected devices** shows nothing until lab 87 deploys the gateway there.
- **vm-appgw-be-0/1 → Networking**: private IPs such as 10.26.2.x — these are the values
  lab 87 consumes via `terraform output backend_ips`.

## Key concepts / gotchas

- **App Gateway needs a dedicated, empty subnet** — the lab pre-creates `snet-appgw` so
  lab 87 can deploy the gateway into it (nothing else may share that subnet).
- The backends have **no public IP and no load balancer yet**; they are reachable only
  from inside the VNet until lab 87 puts the gateway in front.
- Outputs (`backend_ips`, `appgw_subnet_id`) are the handoff point between the two
  labs — a mini module contract made of two configs.
- `count = 2` builds identical NICs and VMs; `[*].id` / `[*].private_ip_address` collect
  them into list outputs.
