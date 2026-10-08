# Lab 57 — App Service logs

Turn on App Service logging to a storage account and the filesystem. HTTP access
logs stream to blob storage; application (stdout/stderr) logs go to the App Service
filesystem. Without this block an App Service logs almost nothing by default.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-applogs` | folder for the lab |
| `azurerm_storage_account` | `stapplogs<6 random chars>` | holds the HTTP logs (blob container is created by Azure) |
| `azurerm_service_plan` | `asp-applogs` | Linux `B1` |
| `azurerm_linux_web_app` | `app-applogs-<6 random chars>` | Node 18-lts, with a `logs {}` block |
| output | `default_hostname` | the app URL |

The `logs` block: `http_logs → azure_blob_storage` (`sas_url` = the storage
account's `primary_blob_connection_string`, 7-day retention) and
`application_logs → file_system_level = "Information"`.

## Commands

Prerequisite: `az login`.

```bash
cd 57-app-service-logs
terraform init
terraform plan
terraform apply
terraform output default_hostname
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-applogs**:

- **App Service** `app-applogs-...` → **Monitoring** → **App Service logs**:
  *Detailed error messages / Failed request tracing / Application logging* are on;
  HTTP logging → *Blob storage*, retention 7 days.
- **Browse** the app (output URL) and hit it a few times, then open the storage
  account `stapplogs...` → **Containers**: a `httplog`-style container appears with
  log blobs inside.
- **Log stream** (under *Monitoring*) shows the app's stdout/stderr live.

## Key concepts / gotchas

- **`http_logs` takes either `azure_blob_storage` or `file_system`, not both** —
  blob is durable; filesystem logs are capped and recycled (that's why the
  `application_logs` path needs a level and disk quota settings).
- **The connection string is a cross-resource reference** —
  `azurerm_storage_account.logs.primary_blob_connection_string` is read from the
  storage resource Terraform manages, so no secret is hard-coded.
- **Blob logs cost storage + egress** — hence `retention_in_days = 7`; destroy the
  lab when you're done.
- Storage account names are globally unique, lowercase letters/digits only — the
  `lower()` + random suffix pattern again.
