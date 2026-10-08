# Lab 99 — Metric alert via Terraform

`azurerm_monitor_metric_alert` watches a metric and fires an action group. This lab
alerts when the VM's CPU goes above 80% for 5 minutes. Point `resource_id` at the VM
from lab 98 (or pass as a variable).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-alert` | Holds only the monitoring resources |
| `azurerm_monitor_action_group.this` | `ag-cpu-alert` | Email receiver `oncall` → your address |
| `azurerm_monitor_metric_alert.cpu` | `alert-cpu-high` | VM "Percentage CPU" Average > 80 over PT5M, severity 2 |
| output `action_group_id` | — | Reusable ID for other alerts |

## Commands

Prerequisite: `az login`, and ideally lab 98 applied first (you need a VM to point at).

```bash
cp terraform.tfvars.example terraform.tfvars   # paste the real VM resource ID + your email
cd 99-metric-alert
terraform init
terraform plan
terraform apply
terraform output action_group_id
terraform destroy
```

Get the VM ID from lab 98 with `terraform output vm_id` (run in `01-monitor-infra`),
or from the portal: VM → Overview → **JSON View** / **Copy resource ID**.

## What to see in the Azure portal

- Resource group **rg-alert**: `ag-cpu-alert` (Action group) and `alert-cpu-high` (Alert rule).
- Open **ag-cpu-alert** → the email receiver named `oncall` shows your address.
- Open **alert-cpu-high** → under **Conditions** you'll see
  "Percentage CPU is greater than 80 with Average aggregation over 5 minutes".
- To actually fire it: SSH into `vm-monitor` (lab 98) and run something like
  `stress-ng --cpu 1 --timeout 600s` (or a busy loop). Alert evaluation is not instant —
  expect several minutes of CPU > 80% before the alert turns **Fired**.

## Key concepts / gotchas

- **Two halves of monitoring**: the *action group* answers "who gets told"; the
  *alert rule* answers "when". They're separate resources wired together by `action_group_id`.
- **scopes is a resource ID**, not a name — that's why lab 98 exported `vm_id`.
- **window_size (PT5M)** controls how long the bad condition must persist; a 5-minute
  window plus Azure's ~1-minute evaluation cycle means alerts lag reality by minutes.
- **severity 2** = warning (0 is critical). Severity drives routing/noise, not urgency by itself.
- The alert rule lives in `rg-alert`, not in the VM's resource group — destroying
  lab 98 leaves the alert in place (watching a deleted ID until you clean up).
