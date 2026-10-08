# Lab 82 — Traffic Manager implementation

The same idea as lab 81 but wired through endpoints with explicit priority weights —
useful for a primary/failover pattern. The first endpoint is `priority=1`, the second
`priority=2`. Traffic Manager sends all traffic to priority 1 and fails over to 2
automatically when the monitor marks it unhealthy.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-tm-impl` | In eastus (primary) |
| `azurerm_service_plan` × 2 (`count`) | `asp-tmimpl-0`, `asp-tmimpl-1` | eastus + westus2 |
| `azurerm_linux_web_app` × 2 (`count`) | `app-tmimpl-0-<suffix>`, `app-tmimpl-1-<suffix>` | Node 18 |
| `azurerm_traffic_manager_profile` | `tmimpl-<suffix>` | Priority routing, TTL 30 |
| `azurerm_traffic_manager_azure_endpoint` × 2 | `ep-eastus` (priority 1), `ep-westus2` (priority 2) | |

## Commands

Prerequisite: `az login`.

```bash
cd labs/section-04-modules-and-networking/82-traffic-manager-impl
terraform init
terraform plan    # 9 resources to add (count blocks: 2 plans, 2 apps)
terraform apply
terraform output  # tm_dns
terraform destroy
```

No `terraform.tfvars` needed.

## What to see in the Azure portal

- Resource group **rg-tm-impl** → **tmimpl-\<suffix\> → Endpoints**: `ep-eastus`
  (priority 1) and `ep-westus2` (priority 2).
- `nslookup <tm_dns>` always returns the eastus app while it's healthy.
- Failover test: **stop** the primary web app (or break its health probe path) and
  within about a minute DNS starts resolving to the westus2 app.

## Key concepts / gotchas

- **Priority routing = active/passive**: unlike lab 81's Performance method, geography
  doesn't matter — priority 1 gets 100% of traffic until it fails health checks.
- **Failover is automatic but not instant**: detection takes a few probe intervals at
  the monitor's settings, and the 30s DNS TTL adds client-side delay.
- Endpoints are typed resources in azurerm 3.x
  (`azurerm_traffic_manager_azure_endpoint` for Azure targets) rather than nested blocks.
- Same profile shape as lab 81 — only `traffic_routing_method` and the `priority`
  attributes change, which shows how little code a routing-policy change costs.
