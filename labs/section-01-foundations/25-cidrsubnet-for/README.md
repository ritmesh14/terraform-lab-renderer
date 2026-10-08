# 25 — `cidrsubnet` / `cidrhost` & `for` (advanced addressing)

Stop hard-coding CIDRs. Derive them from a base with the `cidrsubnet(prefix, newbits, netnum)`
function, and compute host addresses with `cidrhost`. This lab carves four `/26` subnets
out of a single `/20` VNet using a `for` expression, then outputs the first host of each.

Addressing: base VNet `172.18.0.0/20`, subnets `172.18.0.0/26`, `.64/26`, `.128/26`, `.192/26`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-cidrsubnet` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-cidrsubnet` | `172.18.0.0/20` (4,096 addresses) |
| `azurerm_subnet.this` (x4 via `for_each`) | `snet-web`, `snet-app`, `snet-data`, `snet-mgmt` | CIDRs computed by `cidrsubnet(local.base, 6, i)` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/25-cidrsubnet-for
terraform init
terraform plan
terraform apply
terraform output subnets     # name -> {cidr, first_host} map
terraform destroy
```

## What to see

`terraform output subnets` prints, e.g.:

```json
{
  "snet-web"  = { "cidr" = "172.18.0.0/26",   "first_host" = "172.18.0.1" }
  "snet-app"  = { "cidr" = "172.18.0.64/26",  "first_host" = "172.18.0.65" }
  "snet-data" = { "cidr" = "172.18.0.128/26", "first_host" = "172.18.0.129" }
  "snet-mgmt" = { "cidr" = "172.18.0.192/26", "first_host" = "172.18.0.193" }
}
```

In the portal, **Resource groups** → `rg-cidrsubnet` → `vnet-cidrsubnet` → **Subnets**
shows those four computed ranges — nothing was hard-coded in the config.

## Key concepts / gotchas

- `cidrsubnet(prefix, newbits, netnum)`: `newbits` are *added* to the prefix length
  (`/20 + 6 = /26`), and `netnum` selects which of the 2^newbits (= 64 here, we use 0–3)
  slices you want, counting from 0.
- `cidrhost(cidr, n)` returns host number `n` inside a CIDR — `1` is the first usable
  address (`.0` is the network address).
- Changing `newbits` or the base resizes every subnet at once; a plan shows all four
  subnets updating their `address_prefixes` together.
- A single `for` expression over a 4-item tier list produced all names + CIDRs + first
  hosts — the data structure is the design, the code stays identical.
- `for_each` gets the list converted to a map keyed by subnet name (same pattern as
  lab 09), keeping keys stable so subnets are never recreated by reordering.