# Lab 61 — Deploying another SQL Database — prepare data

Before the next database, prepare the schema as a `.sql` file. Lab 63 uploads it.
Here we just author the T-SQL for a `Products` table — no Terraform runs.

## What it creates

Nothing — this lab is a file you write by hand:

| File | Purpose |
|---|---|
| `schema.sql` | creates `dbo.Products` (Id identity PK, Name, Price, CreatedAt) and inserts three rows |

## Commands

Nothing to run yet. Review the T-SQL; lab 63 runs it against the database from
lab 58/12 with `sqlcmd`:

```bash
# no terraform commands in this lab
```

## What to see in the Azure portal

Nothing yet — after lab 63 you'll find the `Products` table in the database from
lab 58 (`sqldb-app`) under **Data Editor / Query editor (preview)** or in SSMS.

## Key concepts / gotchas

- **Terraform provisions infrastructure, not table data** — schema and seed data
  belong in T-SQL migrations, not `.tf` files.
- **`IDENTITY(1,1)`** makes `Id` auto-increment; **`SYSUTCDATETIME()`** defaults
  `CreatedAt` to the UTC timestamp — app code never supplies them.
- **The script is not idempotent** — re-running inserts the three rows again
  (and the `CREATE TABLE` would error). Run it once against a fresh database.
- Keep schema scripts in source control (as this lab does) so the same file can be
  run by a release pipeline later.
