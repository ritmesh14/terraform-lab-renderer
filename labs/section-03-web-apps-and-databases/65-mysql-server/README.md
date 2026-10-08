# Lab 65 — Mini project — MySQL server

Azure Database for MySQL (Flexible Server) is a managed MySQL 8 instance. This lab
creates a Burstable `B1ms` server with public access, a firewall rule for Azure
services, and an admin login from sensitive variables. It's the start of a
three-part mini project (labs 65 → 16 → 18).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-mysql` | folder for the lab |
| `azurerm_mysql_flexible_server` | `mysql-<6 random chars>` | MySQL 8.0.21, `B_Standard_B1ms` (burstable, 1 vCPU / 2 GB), 20 GB storage |
| `azurerm_mysql_flexible_server_firewall_rule` | `AllowAzure` | `0.0.0.0` = allow other Azure services |
| output | `mysql_fqdn` | e.g. `mysql-ab12cd.mysql.database.azure.com` |

Copy `terraform.tfvars.example` → `terraform.tfvars` (one sensitive password).

## Commands

Prerequisite: `az login`.

```bash
cd 65-mysql-server
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
terraform output mysql_fqdn
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-mysql**:

- **Azure Database for MySQL Flexible Server** `mysql-...` → overview shows
  `B_Standard_B1ms`, version 8.0.21, 20 GB storage, and the admin login
  (`mysqladmin`).
- **Networking** — public access is on, with the `AllowAzure` (`0.0.0.0`) rule;
  your own client IP is *not* allowed yet (lab 66 adds it).
- Ports: MySQL listens on **3306**.

## Key concepts / gotchas

- **Flexible Server vs Single Server** — Flexible is the current generation: you
  pick SKU, zone, storage and maintenance window; Single Server is legacy.
- **`B_Standard_B1ms` is burstable** — cheap baseline CPU with burst credits;
  good for labs, throttles under sustained load.
- **`storage {}` is a nested block** — the data-disk size lives inside the server
  resource, not as a separate resource.
- **The `0.0.0.0` firewall rule** means "Azure-internal services may connect" —
  it is not public internet access, and you still need your own client rule to
  connect from a laptop.
- Server names are globally unique (`*.mysql.database.azure.com` DNS), hence the
  random suffix.
