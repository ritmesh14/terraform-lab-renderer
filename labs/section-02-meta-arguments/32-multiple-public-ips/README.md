# Lab 32 — Multiple public IPs

Three static public IPs created with `count`, named with a `format()` expression.

## What it creates

| Terraform resource          | Azure name                          | Notes                                     |
| --------------------------- | ----------------------------------- | ----------------------------------------- |
| `azurerm_resource_group.this` | Resource group `rg-multi-pips`    | 1                                         |
| `azurerm_public_ip.this`    | Public IPs `pip-01`, `pip-02`, `pip-03` | **x3 via `count = local.ip_count`**, Static/Standard |

## Commands

```bash
cd 32-multiple-public-ips
terraform init
terraform plan
terraform apply
terraform output ips
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-multi-pips`: three public IP addresses named `pip-01`…`pip-03`.
  Click one and check **Configuration**: SKU *Standard*, allocation *Static*, and a
  real assigned IP address.
- `terraform output ips` prints the three assigned IP addresses.

## Key concepts / gotchas

- `count.index` starts at 0, so `count.index + 1` makes names start at `pip-01`.
- `format("pip-%02d", n)` zero-pads to 2 digits (`pip-01`, not `pip-1`) so names
  sort correctly; `%d` would print `pip-10` before `pip-2`.
- `Static` + `Standard` keeps the same IP across stop/deallocate (a Dynamic Basic IP
  would change).
- The `ips` output is unknown during plan (`<computed>`) — Azure assigns the address
  at apply time.
- The splat `azurerm_public_ip.this[*].ip_address` gathers one attribute from all
  counted instances into a list.
