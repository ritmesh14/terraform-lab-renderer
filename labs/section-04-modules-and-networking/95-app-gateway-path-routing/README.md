# Lab 95 — Application Gateway — path-based routing (advanced)

Lab 87 used one backend pool. Here a single App Gateway routes by **URL path**: requests
to `/images/*` go to one backend pool, `/video/*` to another, and everything else to a
default pool. This is the building block for hosting several services behind one domain.

The mechanism is the `url_path_map` (a `path_rule` per path + a default) plus a
`request_routing_rule` of type `PathBasedRouting` pointing at it.

Addressing: VNet `172.24.0.0/20`; gateway subnet `172.24.0.0/26`; backend subnet
`172.24.0.64/26`. Backend VMs run nginx (no real services needed for the demo).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-appgw-path` | eastus |
| `azurerm_virtual_network` | `vnet-appgw-path` | 172.24.0.0/20 |
| `azurerm_subnet` × 2 | `snet-appgw`, `snet-backend` | 172.24.0.0/26, 172.24.0.64/26 |
| `azurerm_network_interface` × 3 / `azurerm_linux_virtual_machine` × 3 | `nic-appgw-path-be-N` / `vm-appgw-path-be-N` | One VM per pool |
| `azurerm_public_ip` | `pip-appgw-path` | Gateway frontend |
| `azurerm_application_gateway` | `appgw-path` | Standard_v2, 3 pools + url_path_map |

## Commands

Prerequisite: `az login`. Needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/95-app-gateway-path-routing
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 12 resources to add
terraform apply
terraform output  # appgw_public_ip
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-appgw-path** → **appgw-path → Backend pools**: `be-images`
  (vm-...-0), `be-video` (vm-...-1), `be-default` (vm-...-2).
- **Rules → Path-based**: rule `path-rule` → path map `urlpaths`, with `/images/*` and
  `/video/*` entries and a default pool.
- Browse `http://<appgw_public_ip>/images/`, then `/video/`, then `/` — each shows a
  different backend VM's hostname (one VM per pool makes the mapping visible).

## Key concepts / gotchas

- **One listener, many pools**: the path map does the splitting — the listener itself is
  unchanged from lab 87; only the `request_routing_rule` gains `rule_type =
  "PathBasedRouting"` and `url_path_map_name`.
- **The default pool is mandatory** in the url_path_map: any path not matched by a
  `path_rule` falls back to `default_backend_address_pool_name`.
- Path patterns are case-insensitive prefix rules (`/images/*`) — they match the URL
  path only; host-based routing is the separate `host_path_map`/multi-listener story.
- Each pool is filled by NIC **index** (`backend[0]`, `backend[1]`, …) — with one VM per
  pool the demo is deterministic; with more VMs per pool you'd list several IPs.
- `priority = 1` on the routing rule is mandatory for v2 gateways.
