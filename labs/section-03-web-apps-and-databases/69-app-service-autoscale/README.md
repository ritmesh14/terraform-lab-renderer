# Lab 69 — App Service auto-scale (advanced)

A `B1` plan is fixed-size. This lab puts a web app on an **autoscale-enabled** plan
(`P1v3`) with rules: scale out when CPU > 70%, in when CPU < 30%, between 1 and 3
instances. `azurerm_monitor_autoscale_setting` is the same resource type used for
VMSS — it works on any scalable target, including App Service plans.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-appscale` | folder for the lab |
| `azurerm_service_plan` | `asp-appscale` | **P1v3** — Premium V3, required for autoscale |
| `azurerm_linux_web_app` | `app-appscale-<6 random chars>` | Node 18-lts |
| `azurerm_monitor_autoscale_setting` | `autoscale-asp` | targets the plan; 1–3 instances, CPU 70%/30% rules |
| output | `hostname` | the app URL |

Rules: each one measures `CpuPercentage` (1-minute grain, 5-minute window, average)
and adds/removes 1 instance (`ChangeCount`) with a 1-minute cooldown.

## Commands

Prerequisite: `az login`. Premium V3 costs noticeably more than B1 — destroy when done.

```bash
cd 69-app-service-autoscale
terraform init
terraform plan
terraform apply
terraform output hostname
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-appscale**:

- **App Service plan** `asp-appscale` → **Scale out (App Service plan)**: shows the
  autoscale rule set — 1 default/1 min/3 max instances, two CPU rules.
- Click **Custom autoscale** → the profile `default` with both rules is visible.
- To see it in action you'd have to load the app (a P1v3 app idles at ~1 instance;
  scale-in fires only below 30% CPU).

## Key concepts / gotchas

- **Autoscale changes the plan's instance count**, not the SKU — every app on the
  plan gets more (or fewer) instances of the same size. That's why the setting
  targets `azurerm_service_plan.this.id`.
- **Scale-out and scale-in are separate rules** — a high-CPU rule alone would never
  shrink the fleet; the pair (70%/30%) forms a hysteresis band so instances don't
  flap.
- **`cooldown`** — the wait after a scaling action before the rule may fire again
  (`PT1M` here); ISO-8601 durations like `PT5M` (time window) appear throughout.
- **The metric comes from the plan** — `metric_resource_id` points at the plan, the
  same resource being scaled.
- P1v3 exists so autoscale is possible; the same monitor resource also drives
  VMSS scaling.
