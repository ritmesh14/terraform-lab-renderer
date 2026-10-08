# Lab 112 — Activity log alert + action group webhook (advanced)

Lab 99 made a **metric** alert (numbers over time). Activity-log alerts fire on **control-
plane events** — e.g. "someone deleted a resource group". This lab creates an action group
with a **webhook** receiver and an activity log alert that triggers when a resource group
is deleted in the subscription.

> Set `webhook_url` to your own endpoint (a Slack/Teams incoming webhook, or a
> requestbin for testing).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `data.azurerm_subscription.current` | — | Current subscription ID = alert scope |
| `azurerm_resource_group.this` | `rg-activity-alert` | Holds the monitoring pieces |
| `azurerm_monitor_action_group.this` | `ag-rg-delete` | Webhook receiver `notify-webhook` |
| `azurerm_monitor_activity_log_alert.rg_delete` | `alert-rg-delete` | Administrative / resourceGroups/delete / Critical, subscription scope |
| output `action_group_id` | — | Reusable webhook channel ID |

## Commands

Prerequisite: `az login`.

```bash
cp terraform.tfvars.example terraform.tfvars   # set webhook_url to your endpoint
cd 112-activity-log-alert
terraform init
terraform plan
terraform apply
terraform output action_group_id
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-activity-alert**: action group `ag-rg-delete` and
  alert `alert-rg-delete`.
- Open `alert-rg-delete` → **Condition**: "Delete Resource Group
  (Microsoft.Resources/subscriptions/resourceGroups/delete)" at level Critical,
  scope = your subscription.
- Test it live: delete a throwaway resource group with
  `az group create -n test-throwaway && az group delete -n test-throwaway -y`.
  Within a few minutes the alert turns **Fired** and your webhook receives a JSON
  POST (check requestbin / channel). The activity log (**Monitor → Activity log**)
  shows the delete operation entry that matched.

## Key concepts / gotchas

- **Metric vs activity-log alert**: metric alerts watch *values over time*; activity-log
  alerts watch *events* in the control plane (who did what). No threshold or window here.
- **`criteria.operation_name` is the exact ARM operation string** —
  `Microsoft.Resources/subscriptions/resourceGroups/delete`. Getting the casing/spelling
  right matters; the portal shows all valid operation names.
- **`location = "global"`** is required: the activity log is a subscription-wide,
  region-independent service.
- **Scope is the subscription** (from `data.azurerm_subscription.current`) — so deleting
  *any* resource group, including `rg-activity-alert` itself, fires it.
- **Webhooks are push, not pull**: Azure POSTs the alert JSON to `service_uri`; your
  endpoint must accept it (and Slack/Teams need a small adapter, since Azure's payload
  is not their native format).
- Firing latency is typically 1–5 minutes after the delete event lands in the activity log.
