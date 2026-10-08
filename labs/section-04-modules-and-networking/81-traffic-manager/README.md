# Lab 81 — Traffic Manager — web apps

Traffic Manager is a DNS-based global load balancer: it never proxies traffic, it just
answers DNS with the "best" endpoint. This lab creates two Azure web apps in different
regions (eastus and westeurope) and a Traffic Manager profile using **Performance**
routing, with one `azureEndpoints` endpoint per web app.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-tm` | In eastus |
| `azurerm_service_plan` × 2 (`count`) | `asp-tm-0`, `asp-tm-1` | Linux, B1, one per region |
| `azurerm_linux_web_app` × 2 (`count`) | `app-tm-0-<suffix>`, `app-tm-1-<suffix>` | Node 18, names globally unique |
| `azurerm_traffic_manager_profile` | `tm-<suffix>` | Performance routing, TTL 30 |
| `azurerm_traffic_manager_azure_endpoint` × 2 | `ep-eastus`, `ep-westeurope` | One per web app |

(`random_string` generates the `<suffix>`; it is saved in state so it is stable.)

## Commands

Prerequisite: `az login`. Web app names must be globally unique, hence the random suffix.

```bash
cd labs/section-04-modules-and-networking/81-traffic-manager
terraform init
terraform plan    # 9 resources to add (count blocks: 2 plans, 2 apps)
terraform apply
terraform output  # tm_dns
terraform destroy
```

No `terraform.tfvars` needed.

## What to see in the Azure portal

- Resource group **rg-tm**: two App Service plans, two apps, the Traffic Manager profile.
- **tm-\<suffix\> → Endpoints**: `ep-eastus` and `ep-westeurope`, both Enabled,
  monitoring HTTP / on port 80.
- Browse `http://<tm_dns>` (from `terraform output tm_dns`) — DNS resolves you to the
  app in the region nearest you (check with `nslookup <tm_dns>`).

## Key concepts / gotchas

- **DNS-based routing**: Traffic Manager returns a CNAME to the chosen app's hostname;
  the user's browser then connects directly to that app. Nothing passes through TM.
- **Performance routing** = lowest network latency wins per user — different users get
  different answers. Compare with lab 82's Priority routing (same profile, different
  `traffic_routing_method`).
- **Health monitoring**: `monitor_config` probes every endpoint on HTTP port 80, path `/`;
  unhealthy endpoints drop out of the DNS answers automatically.
- Web app names are global (under `azurewebsites.net`), so the stateful
  `random_string` suffix avoids collisions on re-apply.
