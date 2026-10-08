# Lab 63 — Adding data to an Azure SQL database

Terraform doesn't run T-SQL by design. The recommended path is the **`sqlcmd`** CLI
or a migration tool. After lab 58/12, run:

```bash
sqlcmd -S <server>.database.windows.net -U sqladmin -P "$PASSWORD" \
  -d sqldb-app -i section-03/.../61-another-sql-prepare/schema.sql
```

For CI/CD, a release pipeline step would run this `sqlcmd`. This lab keeps the schema
file you'll execute. (See lab 61 for the `.sql`.)

## What it creates

Nothing — this lab documents the **manual data load**:

| Input | Source |
|---|---|
| `<server>` | `terraform output server_fqdn` from lab 58/12 (without the `:1433` if present) |
| `schema.sql` | authored in lab 61 — creates `dbo.Products`, inserts 3 rows |

## Commands

No Terraform. Run the script manually:

```bash
terraform output server_fqdn    # in the lab-08 (or 12) folder first
sqlcmd -S <server_fqdn> -U sqladmin -P <password> -d sqldb-app -i <path-to>/schema.sql
```

## What to see in the Azure portal

Resource group of the target server (**rg-sql** or **rg-sql-two**) → database
**sqldb-app** → **Query editor (preview)** (or SSMS):

```sql
SELECT * FROM dbo.Products;
```

The three rows (`Widget`, `Gadget`, `Gizmo`) are there, and `CreatedAt` is filled in
by the `SYSUTCDATETIME()` default.

## Key concepts / gotchas

- **Config ≠ data** — Terraform owns servers and databases; table rows come from a
  migration step. Keep the boundary clean or every plan turns noisy.
- **Firewall first** — the machine running `sqlcmd` must be allowed by a lab-09-style
  client rule, or the connection is rejected.
- **`-d sqldb-app`** targets the specific database on the server; the server hosts
  several (lab 62).
- In a real project the same `sqlcmd` call lives in a CI/CD release pipeline so the
  schema lands on staging and prod the same way.
