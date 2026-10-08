# Lab 66 — Mini project — configure the database

Create a database on the server from lab 65 and a firewall rule for your client IP so
you can connect with the `mysql` CLI or MySQL Workbench. The server itself is read
with a **data source** — this lab adds to it, it doesn't manage it.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `data "azurerm_mysql_flexible_server"` | looks up `existing_server_name` in `existing_rg_name` | reads lab 65's server |
| `azurerm_mysql_flexible_database` | `dbapp` | charset `utf8mb4`, collation `utf8mb4_unicode_ci` |
| `azurerm_mysql_flexible_server_firewall_rule` | `AllowClient` | start = end = your `client_ip` |
| outputs | `database_name`, `mysql_fqdn` | for connecting |

Copy `terraform.tfvars.example` → `terraform.tfvars` and fill in the **real server
name** from lab 65 (e.g. from `terraform output mysql_fqdn` in lab 65, or from the
portal), the resource group, your public IP, and a password.

## Commands

Prerequisite: `az login`, and lab 65 applied.

```bash
cd 66-mysql-configure
cp terraform.tfvars.example terraform.tfvars   # point at the lab-15 server
terraform init
terraform plan
terraform apply
terraform output mysql_fqdn
mysql -h <mysql_fqdn> -u mysqladmin -p -D dbapp   # optional connectivity test
terraform destroy    # removes the database + rule, not the server
```

## What to see in the Azure portal

Resource group **rg-mysql** (lab 65's):

- Server `mysql-...` → **Databases**: `dbapp` with `utf8mb4`.
- **Networking**: the `AllowClient` rule with your public IP (start = end).
- Connect from MySQL Workbench using `mysql_fqdn`, user `mysqladmin`, port 3306.

## Key concepts / gotchas

- **`data` vs `resource` again** — the server is *read* (its name is an input
  variable), so `terraform destroy` here leaves the server alone.
- **utf8mb4** — full Unicode including emoji; the default `utf8` charset in MySQL is
  3-byte and cannot store them. `utf8mb4_unicode_ci` is the matching collation.
- **Flexible firewall rules take `resource_group_name` + `server_name`**, not a
  `server_id` — a 3.x API difference from the SQL (`mssql`) firewall rules.
- **Run order matters across labs** — this lab fails to plan until lab 65's server
  exists, exactly like lab 52 depended on lab 51's plan.
- The declared `mysql_admin_password` variable is not actually used by this lab's
  resources (the server already exists) — it's harmless, kept for tfvars symmetry.
