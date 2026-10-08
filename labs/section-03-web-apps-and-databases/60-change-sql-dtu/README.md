# Lab 60 — Change the SQL DTU model (assignment)

Self-check: parameterise the database SKU with a variable and scale by changing
tfvars (`Basic` → `S0` → `S1`). Watch `terraform plan` show the SKU change as an
**in-place update** — no destroy/recreate, the data stays.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-sql-dtu` | folder for the lab |
| `azurerm_mssql_server` | `sqlserver-dtu-<6 random chars>` | SQL 12.0, admin `sqladmin` |
| `azurerm_mssql_database` | `sqldb-dtu` | `sku_name = var.sku_name` (default `Basic`) |
| output | `sku` | the live SKU, for verification |

## Commands

Prerequisite: `az login`.

```bash
cd 60-change-sql-dtu
cp terraform.tfvars.example terraform.tfvars   # password + sku_name
terraform init
terraform apply                 # creates Basic
# edit terraform.tfvars: sku_name = "S1"
terraform plan                  # shows: sku_name Basic -> S1 (in-place)
terraform apply
terraform output sku
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-sql-dtu** → database **sqldb-dtu** → overview:

- The *Compute tier* / *Configure* panel shows the current SKU; after each apply it
  matches the `sku` output.
- The portal can change the tier too (it's the same underlying update Terraform
  performs).

## Key concepts / gotchas

- **DTU vs vCore** — `Basic`, `S0`… are fixed-bundle DTU tiers; vCore tiers are named
  like `GP_Gen5_2` (General Purpose, Gen5, 2 cores). The variable accepts either.
- **SKU change = in-place update** — because `sku_name` is an updatable attribute,
  `terraform plan` shows only an `update` (`~`), never `-/+` destroy/create.
- **Scaling is per database** — on DTU tiers each database has its own SKU; two
  databases on one server can sit on different tiers.
- **Basic → S1 costs more** — S0/S1 add compute; Basic also has the smallest size
  (2 GB) and no VNet-rule support. Destroy when done.
- `sku_name` has a default, so the lab also works with no tfvars at all — only the
  password is required.
