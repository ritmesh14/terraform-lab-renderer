# Lab 111 — Diagnostic settings (advanced)

`azurerm_monitor_diagnostic_setting` streams a resource's logs and metrics to a Log
Analytics workspace, a storage account, or Event Hub. This lab sends a storage account's
`blobServices` logs to a Log Analytics workspace (query); a second storage account with
a private `diag-archive` container is created to stand in for the long-term archive
destination.

Addressing: none (storage + workspace).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | — | 6 chars for unique storage names |
| `azurerm_resource_group.this` | `rg-diag-settings` | eastus |
| `azurerm_log_analytics_workspace.this` | `log-diag-<suffix>` | PerGB2018, 30-day retention |
| `azurerm_storage_account.logs` | `stdiag<suffix>` | Archive destination stand-in |
| `azurerm_storage_container.archive` | `diag-archive` | private; **not yet wired as a diag destination** |
| `azurerm_storage_account.app` | `stdiagapp<suffix>` | The monitored account; versioning + 7-day soft delete |
| `azurerm_monitor_diagnostic_setting.to_la` | `diag-to-loganalytics` | StorageRead + StorageWrite logs, Transaction metrics → workspace |
| outputs `workspace_id` / `app_storage` | — | For tooling / later labs |

## Commands

Prerequisite: `az login`. No tfvars needed.

```bash
cd 111-diagnostic-settings
terraform init
terraform plan
terraform apply
terraform output workspace_id
terraform output app_storage
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-diag-settings**: two storage accounts and one Log Analytics
  workspace.
- Storage account `stdiagapp<suffix>` → **Diagnostic settings** (under *Monitoring*):
  `diag-to-loganalytics`, destination = your workspace, with
  **StorageRead / StorageWrite** logs and **Transaction** metrics ticked.
- Same account → **Data protection**: blob **versioning = Enabled**, soft delete
  for blobs = **7 days**.
- Workspace `log-diag-<suffix>` → **Logs**: after some blob traffic, query
  `StorageBlobLogs | take 10` — entries appear within a few minutes of activity.

## Key concepts / gotchas

- **A diagnostic setting is attached to the resource that emits the data**
  (`target_resource_id`), not to the destination — each monitored resource needs its own.
- **Destinations are optional arguments**: `log_analytics_workspace_id` (query),
  `storage_account_id` (archive), `eventhub_authorization_rule_id` (stream to SIEM).
  This lab wires only Log Analytics — the `diag-archive` container is created but not
  a destination; adding `storage_account_id = azurerm_storage_account.logs.id` would
  complete the compliance pattern.
- **Log categories are resource-specific**: storage uses StorageRead/StorageWrite/
  StorageDelete; SQL uses SQLSecurityAuditEvents (lab 107). The portal's "Add
  diagnostic setting" page lists what each resource offers.
- **Costs flow both ways**: ingestion is charged per GB (PerGB2018); verbose logs on a
  busy storage account add up quickly.
- `blob_properties` on the account (versioning + soft delete) is *data protection*,
  separate from *diagnostics* — both matter for a compliant landing zone.
