# Lab 58 — Azure SQL Database

Create a logical SQL Server and a single database on the cheapest DTU tier (Basic,
5 DTU / 2 GB). The admin password comes from a **sensitive variable** (there's a
`terraform.tfvars.example` to copy). Server and database are separate resources —
create the server, then the database on it.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-sql` | folder for the lab |
| `azurerm_mssql_server` | `sqlserver-<6 random chars>` | SQL 12.0, admin `sqladmin`, TLS ≥ 1.2 |
| `azurerm_mssql_database` | `sqldb-app` | SKU `Basic`, `max_size_gb = 2` |
| outputs | `server_fqdn`, `database_name` | e.g. `sqlserver-ab12cd.database.windows.net` |

## Commands

Prerequisite: `az login`.

```bash
cd 58-sql-database
cp terraform.tfvars.example terraform.tfvars   # then set a real password
terraform init
terraform plan
terraform apply
terraform output server_fqdn
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-sql**:

- **SQL server** `sqlserver-...` → the overview shows the server name and the
  **SQL authentication** admin (`sqladmin`).
- Click the database **sqldb-app** → overview shows `Basic` / 5 DTU / 2 GB.
- **Networking** (on the server) — note there is **no firewall rule yet**: nothing
  can connect from outside Azure. Lab 59 adds rules.
- Connect with SSMS / Azure Data Studio using the output FQDN + `sqladmin` (after
  adding a client firewall rule as in lab 59).

## Key concepts / gotchas

- **"Logical server" ≠ a VM** — it's the management/DNS endpoint that hosts one or
  many databases; you don't choose its size, the database SKU decides.
- **DTU vs vCore** — DTU tiers (Basic, S0…) bundle compute+IO in a fixed measure;
  vCore tiers (GP_Gen5_2…) let you pick cores and storage separately. Basic here =
  cheapest, but it has the tightest limits and no VNet rules.
- **`sensitive = true` masks the password** in plan/apply output — but Terraform
  state stores it in plain text, so protect the state file.
- **No default on the password variable** means `terraform plan` fails until you
  supply it — a deliberate guard.
- Server names are globally unique (`*.database.windows.net` DNS), hence the
  random suffix.
