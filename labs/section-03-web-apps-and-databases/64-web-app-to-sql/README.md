# Lab 64 — Connecting a web app to SQL

Wire a web app to a SQL database by injecting the connection string into the app's
app settings. The connection string comes from the SQL server + database created in
the same lab. The `0.0.0.0` firewall rule lets the Azure-hosted app reach the server,
and the app setting is the standard way apps pick up configuration at runtime.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-webapp-sql` | folder for the lab |
| `azurerm_mssql_server` | `sqlserver-webapp-<6 random chars>` | SQL 12.0, admin `sqladmin` |
| `azurerm_mssql_firewall_rule` | `AllowAzure` | `0.0.0.0` = allow other Azure services (the app) |
| `azurerm_mssql_database` | `sqldb-webapp` | `Basic` |
| `azurerm_service_plan` | `asp-webapp-sql` | Linux `B1` |
| `azurerm_linux_web_app` | `app-webapp-sql-<6 random chars>` | Node 18-lts, `app_settings` holds `DATABASE_URL` |
| outputs | `webapp_hostname`, `sql_fqdn` | app URL and SQL address |

The app setting:

```
DATABASE_URL = Server=tcp:<fqdn>,1433;Database=sqldb-webapp;User Id=sqladmin;Password=<sensitive>;Encrypt=true;
```

## Commands

Prerequisite: `az login`.

```bash
cd 64-web-app-to-sql
cp terraform.tfvars.example terraform.tfvars   # set a real password
terraform init
terraform plan
terraform apply
terraform output webapp_hostname
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-webapp-sql**:

- **App Service** `app-webapp-sql-...` → **Environment variables** (or *Configuration*
  → *Application settings*): the `DATABASE_URL` entry — its value is shown masked
  as a "connection string"-type setting.
- SQL server `sqlserver-webapp-...` → **Networking**: the `AllowAzure`
  (`0.0.0.0`–`0.0.0.0`) rule is what makes the app-to-database connection possible.
- Browse the app URL — the default Node page; an app reading `DATABASE_URL` would
  now reach the DB.

## Key concepts / gotchas

- **App settings = environment variables** — the running app reads
  `process.env.DATABASE_URL`; no config file is baked into the image.
- **`0.0.0.0` rule is required** — without it the app (an Azure service) can't open
  a connection to the server; the app's traffic comes from Azure IPs.
- **The password flows app → app_settings → runtime** — the setting value is
  interpolated from the sensitive variable; it also lives in Terraform state.
- **Everything in one lab** — server, DB, firewall, plan and app are all declared
  here, and Terraform orders them by dependency (app_settings references the
  database, so the DB is created before the app's settings are set).
- Basic (5 DTU) is fine for a demo; real apps need S-tier or vCore.
