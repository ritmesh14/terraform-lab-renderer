# Lab 62 — Deploying another SQL Database — deploy

Provision **two** databases (`sqldb-app`, `sqldb-reports`) on one logical server.
This lab also outputs the **connection string** you'd hand to an app — built by
interpolating the server FQDN and the sensitive password, and marked `sensitive`
so it's masked in output.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-sql-two` | folder for the lab |
| `azurerm_mssql_server` | `sqlserver-two-<6 random chars>` | SQL 12.0, admin `sqladmin` |
| `azurerm_mssql_database` | `sqldb-app` | `Basic` |
| `azurerm_mssql_database` | `sqldb-reports` | `Basic`, same server |
| outputs | `server_fqdn`, `app_conn_string` (sensitive) | ADO connection string for the app DB |

## Commands

Prerequisite: `az login`.

```bash
cd 62-another-sql-deploy
cp terraform.tfvars.example terraform.tfvars   # set a real password
terraform init
terraform plan
terraform apply
terraform output -raw app_conn_string   # -raw because the value is sensitive
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-sql-two** → SQL server `sqlserver-two-...`:

- **Overview → Settings** lists both databases (`sqldb-app`, `sqldb-reports`) — two
  databases, one server/admin, billed per database.
- Click either database → its SKU shows `Basic`.
- The connection string output matches what the portal shows on the database
  (`Connection strings` → ADO.NET), with your password filled in.

## Key concepts / gotchas

- **One server, many databases** — the two database resources both reference
  `server_id`; the server is shared infrastructure, the databases are independent
  units (own SKU, own users).
- **String interpolation builds the connection string** —
  `"Server=tcp:${...fqdn},1433;Database=sqldb-app;..."`; the password is pulled
  straight from the sensitive variable.
- **`sensitive = true` on the output** — `terraform output` refuses to print it
  without `-raw` (or `terraform output -json`); it's also masked in apply logs.
  The value still lands in state in plain text.
- Port **1433** is the standard SQL Server wire port.
- Like lab 58, no firewall rules yet — connections only work after lab-09-style
  rules are added.
