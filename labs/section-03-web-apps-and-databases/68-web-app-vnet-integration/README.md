# Lab 68 — Mini project — App Service virtual network integration

When your database is private (no public access), the web app needs a VNet
integration to reach it. This lab creates a VNet, a subnet **delegated** to
`Microsoft.Web/serverFarms`, and wires the web app to that subnet with
`vnet_route_all_enabled = true`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-webapp-vnet` | folder for the lab |
| `azurerm_virtual_network` | `vnet-webapp` | address space `10.253.0.0/16` |
| `azurerm_subnet` | `snet-webapp` | `10.253.1.0/26` (64 addresses), delegated to `Microsoft.Web/serverFarms` |
| `azurerm_service_plan` | `asp-vnet` | **S1** — Standard tier; VNet integration needs Basic+ won't do it, so this lab upgrades to S1 |
| `azurerm_linux_web_app` | `app-vnet-<6 random chars>` | Node 18-lts, bound to the subnet |
| output | `webapp_hostname` | the app URL |

## Commands

Prerequisite: `az login`.

```bash
cd 68-web-app-vnet-integration
terraform init
terraform plan
terraform apply
terraform output webapp_hostname
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-webapp-vnet**:

- **App Service** `app-vnet-...` → **Networking** → *Outbound traffic* → **Virtual
  network integration**: shows `snet-webapp`, and "Route all" enabled.
- **Virtual network** `vnet-webapp` → **Subnets**: `snet-webapp` with the
  delegation `Microsoft.Web/serverFarms`.
- The app URL still serves publicly; the integration is about *outbound* traffic.

## Key concepts / gotchas

- **Delegation is mandatory** — the subnet must be delegated to
  `Microsoft.Web/serverFarms` or the integration is rejected; that's also why the
  subnet needs free space (some addresses are reserved by the platform).
- **`vnet_route_all_enabled = true`** — sends *all* outbound traffic through the
  VNet, not just RFC1918 (private) addresses. It lives inside `site_config`, not at
  the resource's top level.
- **Plan tier matters** — regional VNet integration requires Standard or higher;
  the earlier labs' B1 plan can't do it, hence `S1` here.
- **This only makes the app a VNet member** — a private database would live in
  another subnet (with private endpoints / `public_network_access_enabled = false`);
  this lab keeps focus on the integration plumbing.
- 1 S1 instance runs 24/7 — destroy the lab when you finish.
