# Lab 72 — MySQL Flexible Server — configuration & HA (advanced)

Beyond the basics (lab 65), MySQL Flexible Server lets you tune server parameters and
run zone-redundant high availability. This lab:

- sets `high_availability` to `ZoneRedundant` (2 instances across zones),
- tunes a server configuration value (`max_connections`) with
  `azurerm_mysql_flexible_server_configuration`,
- enables a maintenance window so patching is predictable.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-mysql-adv` | folder for the lab |
| `azurerm_mysql_flexible_server` | `mysql-adv-<6 random chars>` | 8.0.21, `B_Standard_B1ms`, 20 GB, `zone = "1"`, HA `ZoneRedundant`, maintenance Sunday 02:00 |
| `azurerm_mysql_flexible_server_configuration` | `max_connections = 200` | one server parameter |
| output | `mysql_fqdn` | the connect address |

Copy `terraform.tfvars.example` → `terraform.tfvars` (one sensitive password).

## Commands

Prerequisite: `az login`.

```bash
cd 72-mysql-parameters
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
terraform output mysql_fqdn
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-mysql-adv** → server `mysql-adv-...`:

- **Overview**: *High availability* shows `ZoneRedundant` — a standby in another
  availability zone (see also *Zone redundant high availability* on the compute+storage page).
- **Server parameters**: `max_connections` = 200 (search for it).
- **Maintenance**: the weekly window, Sunday 02:00 (`day_of_week 0`, `start_hour 2`).

## Key concepts / gotchas

- **Zone-redundant HA runs a standby** — writes go to the primary in zone 1; on a
  zone failure Azure fails over to the standby automatically. HA doubles compute
  cost (two instances) — expect the price to be double the B1ms rate.
- **HA has SKU requirements** — Azure documents zone-redundant HA for Burstable
  storage/compute only in certain configurations; if `apply` is rejected with an
  SKU/HA error, that's the provider/Azure constraint showing through (not a
  Terraform problem).
- **Server parameters are first-class resources** — `azurerm_mysql_flexible_server_configuration`
  sets one key/value; the `name` is the exact parameter name MySQL exposes.
- **Maintenance window** — `day_of_week = 0` is Sunday in this API (0 = Sunday);
  patching (including HA failover-causing maintenance) lands in that window.
- Changing HA or the window is an in-place server update; watch `plan` show `~`.
