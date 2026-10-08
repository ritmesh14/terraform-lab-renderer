# Lab 105 — Landing Zone — logging

Centralise logs in one Log Analytics workspace in the security RG, plus a storage account
for long-term archive. Diagnostic settings (added per resource) point at this workspace.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | — | 6 chars making names unique |
| `azurerm_resource_group.sec` | `rg-lz-sec` | Security/logging home |
| `azurerm_log_analytics_workspace.this` | `log-lz-<suffix>` | PerGB2018, 30-day retention |
| `azurerm_storage_account.logs` | `stlzlogs<suffix>` | Standard LRS, TLS 1.2 minimum |
| outputs `workspace_id` / `logs_sa` | — | For wiring diagnostic settings later |

## Commands

Prerequisite: `az login`. No tfvars needed.

```bash
cd 105-landing-zone-logging
terraform init
terraform plan
terraform apply
terraform output workspace_id
terraform output logs_sa
terraform destroy
```

## What to see in the Azure portal

Open resource group **rg-lz-sec**. You'll see `log-lz-<suffix>` and `stlzlogs<suffix>`:

- **Log Analytics workspace → Logs**: KQL query window (empty until lab 111 feeds data).
- **Storage account → Networking**: shows "Minimum TLS version: TLS 1.2".
- Nothing flows here yet — both are just destinations until a diagnostic setting
  points a resource at them.

## Key concepts / gotchas

- **Two destinations, two purposes**: the workspace is for interactive querying
  (fast, expensive per GB, 30-day retention); the storage account is cheap long-term
  archive. Diagnostic settings can send to both at once.
- **Location matters for log routing**: a workspace can accept logs from other
  regions, but same-region routing is simpler/cheaper — landing zones usually pin
  the workspace to the primary region.
- **`min_tls_version = "TLS1_2"`** is a typical landing-zone hardening default applied
  uniformly to every storage account.
- This workspace is *the* landing zone workspace — lab 111 (diagnostic settings) and
  lab 112 (activity-log alerts) build on this pattern of "all logs flow to one place".
