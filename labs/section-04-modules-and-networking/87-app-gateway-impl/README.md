# Lab 87 — Application Gateway — implementation

A self-contained Application Gateway v2 with a public frontend, a backend pool of two
IPs, an HTTP listener on port 80, and a basic request routing rule. Combine with lab 86
backends by pointing the pool at their private IPs.

An App Gateway config is a chain of named blocks that reference each other by name:
`frontend_port` + `frontend_ip_configuration` → `http_listener` →
`request_routing_rule` → `backend_address_pool` + `backend_http_settings`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-appgw-impl` | eastus |
| `azurerm_virtual_network` / `azurerm_subnet` | `vnet-appgw-impl` / `snet-appgw` | 10.27.0.0/16, 10.27.1.0/24 (gateway-only subnet) |
| `azurerm_public_ip` | `pip-appgw` | Standard — the gateway's frontend |
| `azurerm_application_gateway` | `appgw` | Standard_v2, capacity 1 |
| — pool / settings / listener / rule inside it | `be-pool`, `http-settings`, `listener`, `rule` | The chain above |

## Commands

Prerequisite: `az login`. This lab takes the backend VM private IPs as input — copy the
example and paste the values from `terraform output backend_ips` in lab 86:

```bash
cd labs/section-04-modules-and-networking/87-app-gateway-impl
cp terraform.tfvars.example terraform.tfvars   # then fill in backend_ips = ["10.26.2.x", "10.26.2.y"]
terraform init
terraform plan    # 5 resources to add
terraform apply
terraform output  # appgw_public_ip
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-appgw-impl** → **appgw**.
- **appgw → Backend pools → be-pool**: the two IP addresses you passed in; health
  probe status turns healthy (default probe on the http settings).
- **Listeners / Rules**: `listener` on port 80 → basic rule → `be-pool`.
- Browse `http://<appgw_public_ip>` — the page alternates between the two lab-14
  backends, and requests now come from the gateway's subnet (10.27.1.x).

## Key concepts / gotchas

- **L7 vs L4**: an App Gateway understands HTTP — it can route by path/host/cookie and
  terminate TLS (lab 96), while the lab 79 Load Balancer just forwards packets by port.
- **The gateway needs its own subnet** (`gateway_ip_configuration → subnet_id`);
  v2 also wants at least a /26 and no other resources in it.
- Every sub-block (`frontend_port`, `backend_address_pool`, …) is referenced **by name**
  (`frontend_port_name = "http"`, `backend_address_pool_name = "be-pool"`) — typos only
  surface at apply time, so the names must match exactly.
- `priority` on the routing rule is mandatory for v2 (evaluation order, 1 = highest).
- `backend_ips` come from lab 86's outputs — this is module-style wiring done across two
  separate configs (run lab 86 first, destroy lab 86 and the pool breaks).
