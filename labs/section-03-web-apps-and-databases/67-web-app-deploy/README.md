# Lab 67 — Mini project — deploy the Azure web app

Deploy a web app that points at the MySQL database. The MySQL connection string is
built from the MySQL server (re-declared here for completeness) and stored in the
web app's `app_settings` as `DATABASE_URL` — the URL format Node apps typically use.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-webapp-mysql` | folder for the lab |
| `azurerm_mysql_flexible_server` | `mysql-web-<6 random chars>` | 8.0.21, `B_Standard_B1ms`, 20 GB |
| `azurerm_mysql_flexible_database` | `dbapp` | `utf8mb4` |
| `azurerm_service_plan` | `asp-webapp-mysql` | Linux `B1` |
| `azurerm_linux_web_app` | `app-mysql-<6 random chars>` | Node 18-lts, `app_settings.DATABASE_URL` |
| outputs | `webapp_hostname`, `mysql_fqdn` | app URL and MySQL address |

The app setting is:

```
DATABASE_URL = mysql://mysqladmin:<sensitive password>@<fqdn>:3306/dbapp
```

Note: unlike labs 65/16 there is **no firewall rule** here — see the gotchas.

## Commands

Prerequisite: `az login`.

```bash
cd 67-web-app-deploy
cp terraform.tfvars.example terraform.tfvars   # set a real password
terraform init
terraform plan
terraform apply
terraform output webapp_hostname
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-webapp-mysql**:

- **App Service** `app-mysql-...` → **Environment variables**: `DATABASE_URL` shows
  the `mysql://...` connection string (value masked).
- Server `mysql-web-...` → **Databases**: `dbapp`.
- Browse the app URL — the default Node page; an app reading `DATABASE_URL` would
  reach MySQL on port 3306.

## Key concepts / gotchas

- **Two connection-string styles** — SQL uses the ADO `Server=tcp:...` format
  (lab 64), MySQL uses the URL form `mysql://user:pass@host:3306/db`. Same idea:
  a value the app reads from its environment.
- **The password is interpolated into the URL** — and the setting carries the
  sensitive value into the app runtime; it also sits in Terraform state.
- **No firewall rule is created in this lab** — this config declares no
  `azurerm_mysql_flexible_server_firewall_rule` (compare lab 65's `0.0.0.0` rule).
  If the app can't reach the server, add a rule like lab 65's to allow Azure
  services.
- **Self-contained by design** — the server is re-declared here rather than read
  with a data source, so this lab stands alone (contrast with lab 66).
- Everything is dependency-ordered by Terraform: server → database → app with the
  interpolated app setting.
