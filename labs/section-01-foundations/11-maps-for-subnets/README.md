# 11 — Maps for subnets (assignment)

Self-check assignment: parameterise subnets as a **variable** typed as
`map(object({...}))` so the same module can deploy different subnet layouts without code
changes. This is the bridge from lab 10: the map moved from `locals` into a typed
variable fed by `terraform.tfvars`.

Try it: open `terraform.tfvars` and change the subnet map, then `terraform plan` to see
the diff before applying.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-subnetmap-foundation` | Location from `var.location` |
| `azurerm_virtual_network.this` | `vnet-subnetmap` | `10.70.0.0/16` |
| `azurerm_subnet.this` (x3 via `for_each`) | `snet-web`, `snet-app`, `snet-data` | One per entry in `var.subnets` |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01).

```bash
cd section-01-foundations/11-maps-for-subnets
terraform init
terraform plan        # values come from terraform.tfvars
terraform apply
terraform output subnet_names
terraform destroy
```

## What to see in the Azure portal

**Resource groups** → `rg-subnetmap-foundation` → `vnet-subnetmap` → **Subnets**: the
subnets match `terraform.tfvars` exactly — `snet-web` 10.70.1.0/24, `snet-app`
10.70.2.0/24, `snet-data` 10.70.3.0/24.

## Key concepts / gotchas

- `map(object({ prefix = string, nsg = bool }))` is a **typed structure**: tfvars values
  must match the shape exactly, or Terraform errors before any plan.
- `terraform.tfvars` is auto-loaded by name — that is where the subnet map lives, so
  changing the layout means editing data, not code.
- The `nsg` flag in each object is carried but not used yet — it sets up the pattern for
  later NSG labs; keeping unused fields in the variable shape is normal while a module
  grows.
- `length(var.subnets)` and `keys(azurerm_subnet.this)` in outputs.tf show how a
  for_each resource behaves like a map you can query.
- **Assignment spirit:** add a fourth subnet (e.g. `cache = { prefix = "10.70.4.0/24",
  nsg = false }`) to tfvars and `plan` — only one new subnet should appear, proving the
  keys keep the rest stable.