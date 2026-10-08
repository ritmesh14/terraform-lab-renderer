# Lab 71 — Azure SQL with Microsoft Entra ID admin (advanced)

SQL logins are passwords. Entra ID (Azure AD) admin lets you sign in with an
identity — no shared password, better audit, and you can scope who's a DB admin by
group membership. This lab sets the SQL server's Entra admin to the current
signed-in principal via `azuread_administrator`.

> Also demonstrates `identity { type = "SystemAssigned" }` so the server can later use
> managed identity to connect to other resources.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-sql-entra` | folder for the lab |
| `data "azurerm_client_config"` | — | reads the identity running Terraform (you, after `az login`) |
| `azurerm_mssql_server` | `sql-entra-<6 random chars>` | SQL 12.0; bootstrap admin `sqladmin`; `azuread_administrator` = "EntraAdmin" (your object_id/tenant_id); `identity` SystemAssigned |
| `azurerm_mssql_database` | `sqldb-entra` | `Basic` |
| output | `server_fqdn` | the connect address |

## Commands

Prerequisite: `az login` — the data source reads the identity you're signed in as,
so the Entra admin is set to *your* account.

```bash
cd 71-sql-entra-admin
terraform init
terraform plan
terraform apply
terraform output server_fqdn
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-sql-entra** → SQL server `sql-entra-...`:

- **Microsoft Entra ID** (under *Settings*): admin named `EntraAdmin` pointing at
  your user — this is the identity you can log in with using **Microsoft Entra
  MFA / universal authentication** in SSMS.
- **Identity** (or in the server's overview): a system-assigned managed identity
  was created — an app registration-like principal owned by the server.
- Click the database **sqldb-entra** → overview shows `Basic`.

## Key concepts / gotchas

- **`data.azurerm_client_config.current`** returns the caller's `object_id` and
  `tenant_id`; those are interpolated into `azuread_administrator`, so whoever runs
  `apply` becomes the admin.
- **Two auth paths coexist** — the SQL login `sqladmin` remains for bootstrapping,
  but the *intended* sign-in is Entra auth; in production you'd drop or rotate the
  password login. (Note: this lab hard-codes `"ChangeMe12345!"` as the required
  password field — a teaching simplification, not a pattern to copy.)
- **`SystemAssigned` identity** gives the *server itself* an identity that other
  Azure resources can trust later — the same mechanism apps use to connect without
  secrets.
- No firewall rules here either — connecting (even with Entra auth) requires a
  lab-09-style client rule first.
- `prevent_destroy`-style caution applies: destroying the server destroys its
  databases.
