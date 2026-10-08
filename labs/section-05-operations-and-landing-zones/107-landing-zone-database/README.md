# Lab 107 — Landing Zone — database deployment

An Azure SQL logical server + database in the data RG, with a firewall rule allowing
other Azure services (so the app can connect) and a diagnostic setting streaming to the
Log Analytics workspace from lab 105.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | — | 6 chars making the server name unique |
| `azurerm_resource_group.data` | `rg-lz-db` | eastus |
| `azurerm_mssql_server.this` | `sql-lz-<suffix>` | SQL 12.0, admin `sqladmin`, TLS 1.2 |
| `azurerm_mssql_firewall_rule.azure` | `AllowAzure` | 0.0.0.0 = "allow Azure services" |
| `azurerm_mssql_database.this` | `sqldb-lz` | SKU S0 |
| `azurerm_monitor_diagnostic_setting.sql` | `diag-sql` | Audit log + metrics → lab 105 workspace |
| output `server_fqdn` | — | `<server>.database.windows.net` |

## Commands

Prerequisite: `az login`, and **lab 105 applied first** (you need its workspace ID).

```bash
cp terraform.tfvars.example terraform.tfvars   # set a password + the workspace ID from lab 105
cd 107-landing-zone-database
terraform init
terraform plan
terraform apply
terraform output server_fqdn
terraform destroy
```

Get the workspace ID with `terraform output workspace_id` run in `08-landing-zone-logging`.

## What to see in the Azure portal

- Resource group **rg-lz-db**: the server `sql-lz-<suffix>` and database `sqldb-lz`.
- Server → **Networking / Firewalls and virtual networks**: the rule "AllowAzure"
  with 0.0.0.0 ("Allow Azure services and resources to access this server").
- Database `sqldb-lz` → **Diagnostic settings**: `diag-sql` sending
  SQLSecurityAuditEvents + AllMetrics to your Log Analytics workspace.
- Database → **Logs**: query `SQLSecurityAuditEvents` once audit events start arriving.

## Key concepts / gotchas

- **A SQL *logical server* is not the database.** The server is the management and
  connection endpoint (`*.database.windows.net`); databases live on it.
- **The 0.0.0.0 firewall rule is Azure's special value** meaning "connections from
  inside Azure" — it does *not* open the server to the internet. For your laptop you'd
  add a rule with your client IP.
- **`sensitive = true`** keeps the password out of plan/apply output and state listings;
  the value still lands in state (encrypted at rest) — real deployments would use
  Key Vault references instead.
- **Diagnostic setting wiring**: `target_resource_id` = what emits the data (the
  database), `log_analytics_workspace_id` = where it goes (lab 105's workspace). This
  is the lab-14 pattern applied to SQL.
- SQL audit events take a few minutes to appear in the workspace after apply.
