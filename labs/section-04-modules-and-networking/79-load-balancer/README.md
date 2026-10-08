# Lab 79 — Azure Load Balancer

A public Standard Load Balancer distributes port 80 traffic across two backend VMs.
The four LB pieces are separate Terraform resources that reference each other:
frontend IP (the public IP clients hit), backend address pool (the VM NICs), a health
probe, and a rule that maps frontend port → backend port using the probe.

The two VMs run nginx via cloud-init, each serving a page stamped with its hostname so
you can watch the load balancing flip between them.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-lb` | |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-lb` / `snet-web` | 10.16.0.0/16, 10.16.1.0/24 |
| `azurerm_network_security_group` | `nsg-lb` | Allow inbound 80 + 22 |
| `azurerm_network_interface` × 2 (`count`) | `nic-lb-0`, `nic-lb-1` | Private IPs only |
| `azurerm_linux_virtual_machine` × 2 (`count`) | `vm-lb-0`, `vm-lb-1` | nginx via cloud-init |
| `azurerm_public_ip` | `pip-lb` | Standard / static — the LB's frontend |
| `azurerm_lb` | `lb-web-public` | Standard SKU |
| `azurerm_lb_backend_address_pool` | `be-pool` | Holds the two NICs |
| `azurerm_lb_probe` | `http-probe` | HTTP GET / every 5s, 2 probes to fail |
| `azurerm_lb_rule` | `http-rule` | Frontend 80 → backend 80 |

## Commands

Prerequisite: `az login`. This lab needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/79-load-balancer
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 15 resources to add (count blocks expand: 2 NICs, 2 VMs, 2 pool joins)
terraform apply
terraform output  # lb_public_ip
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-lb**.
- **lb-web-public → Frontend IP configuration**: shows `pip-lb`.
- **Backend pools → be-pool**: both `nic-lb-0` and `nic-lb-1` listed.
- **Health probes / Load balancing rules**: `http-probe`, `http-rule`.
- Browse `http://<lb_public_ip>` and refresh — the `<h1>backend …</h1>` hostname
  alternates between the two VMs.

## Key concepts / gotchas

- **A load balancer is four resources, not one**: `azurerm_lb` + backend pool + probe +
  rule. The rule is what ties them together (`frontend_ip_configuration_name`,
  `backend_address_pool_ids`, `probe_id`).
- **Probe thresholds**: a VM is marked unhealthy after the probe fails repeatedly
  (`number_of_probes` = 2 consecutive failures here); unhealthy backends get no traffic.
- Backend NICs have **no public IP** — the LB owns the only public address; the
  NIC→pool association resource is what enrolls each VM.
- Standard SKU is required for a public LB frontend + zone support; the public IP must
  also be Standard.
- `count` with `count.index` builds the two identical backends; each association resource
  references its NIC with the same index.
