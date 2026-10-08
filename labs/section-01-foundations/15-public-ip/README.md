# 15 — Public IP Address

`azurerm_public_ip` gives a resource a routable IP. This lab provisions a static Standard
public IP and reads the assigned address as an output. Compare the `allocation_method`
and `sku` options (`Basic` vs `Standard`, `Static` vs `Dynamic`).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-pip-foundation` | Container for the lab |
| `azurerm_public_ip.web` | `pip-web-01` | Static allocation, Standard SKU |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/15-public-ip
terraform init
terraform plan
terraform apply
terraform output public_ip
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-pip-foundation` → `pip-web-01` → **Overview**. Verify:
- **IP address**: the same value `terraform output public_ip` printed.
- **SKU**: Standard, **Assignment**: Static.
- Note it is *not* attached to anything yet — the association to a NIC happens in later
  VM labs.

## Key concepts / gotchas

- `allocation_method = "Static"` **reserves the address** for the resource's lifetime —
  it survives a VM being stopped. `"Dynamic"` releases the IP when the VM stops, and you
  get a new one on start.
- `sku = "Standard"` is the modern SKU (zone-redundant, always Static); `"Basic"` is the
  legacy one and is being retired — prefer Standard everywhere.
- `ip_address` is **computed by Azure at creation**, so it is read as an output, never
  written in code.
- A public IP is a standalone object: creating it does nothing until something (NIC,
  load balancer, gateway) is associated with it.
- Destroying the resource releases the address — there is no way to "keep" an IP across
  a destroy except reserving it.