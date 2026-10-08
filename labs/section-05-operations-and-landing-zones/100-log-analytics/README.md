# Lab 100 — Log Analytics workspace via Terraform

A Log Analytics workspace collects logs and metrics. Tie a VM (or a storage account)
to it with a diagnostic setting to start streaming data.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | — | 6 lowercase chars making the workspace name unique |
| `azurerm_resource_group.this` | `rg-loganalytics` | eastus |
| `azurerm_log_analytics_workspace.this` | `log-<suffix>` | PerGB2018 sku, 30-day retention |

## Commands

Prerequisite: `az login`. This lab needs no variables or tfvars file.

```bash
cd 100-log-analytics
terraform init
terraform plan
terraform apply
terraform output workspace_id      # full resource ID (for diagnostic settings)
terraform output customer_id       # workspace GUID (for agents / KQL API)
terraform destroy
```

## What to see in the Azure portal

Search for **Log Analytics workspaces** (or open **rg-loganalytics**). You'll find
`log-<suffix>`:

- **Overview** shows the *Workspace ID* (GUID — the `customer_id` output) and the
  *Primary/Secondary shared keys*.
- Open **Logs**, run a trivial query like `Heartbeat | take 10` — the table will be
  empty until a diagnostic setting (lab 111) starts feeding data in.
- Under **Usage and estimated costs** you can see how the PerGB2018 billing works.

## Key concepts / gotchas

- A **workspace** is the landing spot for logs/metrics; resources only send data
  once something points them here (a *diagnostic setting*, lab 111).
- **PerGB2018** means you pay for data ingested; **retention_in_days = 30** means
  older data is deleted (longer retention costs extra).
- The workspace name must be globally unique, hence the `random_string` suffix. The
  value is stored in Terraform state, so it stays stable across plans/applies —
  only a destroy/regenerate produces a new name.
- The two outputs are easy to confuse: `workspace_id` here is the **resource ID**
  (`.../workspaces/log-xxxx`), `customer_id` is the **GUID**. Lab 111 uses the first.
