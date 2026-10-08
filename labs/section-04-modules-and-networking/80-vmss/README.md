# Lab 80 — Virtual Machine Scale Set

A VMSS deploys identical VMs that auto-scale. This lab uses a Linux VMSS behind a
public Standard Load Balancer with autoscale rules: scale out above 75% CPU, in below
25%. Cloud-init installs nginx so the scale set serves HTTP. Unlike lab 79, no
individual VMs exist to join a pool — the scale set's NIC configuration references the
backend pool directly.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-vmss` | |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-vmss` / `snet-web` | 10.17.0.0/16, 10.17.1.0/24 |
| `azurerm_network_security_group` | `nsg-vmss` | Allow inbound 80 |
| `azurerm_public_ip` | `pip-vmss` | LB frontend |
| `azurerm_lb` | `lb-vmss` | Standard, frontend `fe` |
| `azurerm_lb_backend_address_pool` | `be-vmss` | Instances join via their NIC config |
| `azurerm_lb_probe` | `http` | HTTP GET / |
| `azurerm_lb_rule` | `http` | 80 → 80 |
| `azurerm_linux_virtual_machine_scale_set` | `vmss-web` | 2 instances (min 2, max 5), nginx |
| `azurerm_monitor_autoscale_setting` | `autoscale-vmss` | CPU-based scale out/in |

## Commands

Prerequisite: `az login`. This lab needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/80-vmss
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # ~12 resources to add
terraform apply
terraform output  # lb_public_ip
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-vmss** → **vmss-web → Instances**: 2 instances running.
- **lb-vmss → Backend pools → be-vmss**: both scale-set instances attached.
- **autoscale-vmss** (Monitor → Autoscale): profile with default/min 2, max 5, and the
  two CPU rules (GreaterThan 75 → +1, LessThan 25 → −1).
- Load-test it (e.g. `ab -n 10000 -c 50 http://<ip>/` from your machine or any VM) and
  watch **vmss-web → Instances** climb toward 5, then drop back.

## Key concepts / gotchas

- **The scale set joins the LB in one place**: the NIC's
  `load_balancer_backend_address_pool_ids` inside `ip_configuration` — there is no
  per-NIC association resource because instances come and go.
- **Autoscale is an Azure Monitor resource**, not a VMSS property:
  `azurerm_monitor_autoscale_setting` targets the VMSS via `target_resource_id`.
- Capacity bounds (`minimum`/`maximum`) cap the rules — no amount of load exceeds 5
  instances here; `default` is used when no rule matches.
- ISO-8601 durations everywhere: `PT1M` (1 min), `PT5M` (5 min) for metric windows and
  cooldowns.
- `instances = 2` is the *initial* count; the autoscale profile's min/max take over
  after deployment — changing `instances` later won't fight the autoscaler forever.
