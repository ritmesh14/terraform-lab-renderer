# Lab 94 — Internal Load Balancer (advanced)

Lab 79 made a *public* LB. Here the frontend IP is **private** (inside a VNet), so the
load-balanced service is only reachable from inside the network — the classic pattern for
fronting an internal API behind a public gateway/firewall. Two backend VMs run nginx.
Everything else (pool, probe, rule) is identical to lab 79; only the frontend changes.

Addressing: VNet `172.23.0.0/20`; backend subnet `172.23.0.0/26`; frontend subnet
`172.23.0.64/26` (the LB's private frontend IP `172.23.0.68` lives here).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-internal-lb` | eastus |
| `azurerm_virtual_network` | `vnet-internal-lb` | 172.23.0.0/20 |
| `azurerm_subnet` × 2 | `snet-backend`, `snet-frontend` | 172.23.0.0/26, 172.23.0.64/26 |
| `azurerm_network_security_group` | `nsg-internal-lb` | Allow inbound 80 |
| `azurerm_network_interface` × 2 / `azurerm_linux_virtual_machine` × 2 | `nic-internal-be-N` / `vm-internal-be-N` | nginx via cloud-init |
| `azurerm_lb` | `lb-internal` | **Private** frontend 172.23.0.68 |
| `azurerm_lb_backend_address_pool` / probe / rule | `be-internal` / `http` / `http` | Same shape as lab 79 |

## Commands

Prerequisite: `az login`. Needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/94-internal-load-balancer
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 14 resources to add
terraform apply
terraform output  # lb_private_ip
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-internal-lb** → **lb-internal → Frontend IP configuration**:
  a **private** IP `172.23.0.68` in `snet-frontend` — no public IP anywhere.
- **Backend pools → be-internal**: both `vm-internal-be-*` NICs.
- The LB is invisible from the internet by design — connect to a VM first, then
  `curl http://172.23.0.68/` from *inside* the VNet and watch the hostname flip.

## Key concepts / gotchas

- **Internal vs public LB differs in exactly one block**:
  `frontend_ip_configuration` uses `subnet_id` + `private_ip_address_allocation =
  "Static"` + `private_ip_address` instead of a `public_ip_address_id`.
- The static frontend IP (172.23.0.68) is chosen inside the frontend subnet's range —
  picking it yourself makes the service's address stable for callers/DNS.
- Azure recommends the LB frontend lives in its **own subnet**, separate from the
  backends — hence the second subnet here.
- Everything else is the four-resource LB pattern from lab 79: `azurerm_lb` + pool +
  probe + rule. Internal LBs are also the standard frontend for SQL Always On
  listeners and private AKS ingress.
