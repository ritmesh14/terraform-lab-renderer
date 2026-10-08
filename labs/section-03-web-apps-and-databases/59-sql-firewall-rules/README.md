# Lab 59 — SQL Database — firewall rules

By default, nothing can reach your SQL logical server. Add firewall rules:
- one for your client IP (so you can connect from SSMS / Azure Data Studio)
- one for Azure services (`0.0.0.0`–`0.0.0.0`) so App Service can reach it

Both need `terraform.tfvars` (see `terraform.tfvars.example`: password + your
public client IP).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-sql-fw` | folder for the lab |
| `azurerm_mssql_server` | `sqlserver-fw-<6 random chars>` | fresh copy of the lab-08 server so this lab is self-contained |
| `azurerm_mssql_firewall_rule` | `AllowClient` | `start_ip = end_ip = var.client_ip` (a single address) |
| `azurerm_mssql_firewall_rule` | `AllowAzureServices` | `0.0.0.0`–`0.0.0.0` = "other Azure services" |
| output | `server_fqdn` | the connect address |

## Commands

Prerequisite: `az login`. Find your public IP first (`curl ifconfig.me` or search
"what is my IP").

```bash
cd 59-sql-firewall-rules
cp terraform.tfvars.example terraform.tfvars   # set password + your client IP
terraform init
terraform plan
terraform apply
terraform output server_fqdn
terraform destroy
```

## What to see in the Azure portal

Resource group **rg-sql-fw** → SQL server `sqlserver-fw-...` → **Networking**:

- **Firewall rules** lists both rules: `AllowClient` with your IP (start = end =
  that single address) and `AllowAzureServices` (`0.0.0.0`–`0.0.0.0`).
- Now connect from SSMS/Azure Data Studio with the FQDN + `sqladmin` — without the
  client rule the connection fails with a firewall error.

## Key concepts / gotchas

- **Deny by default** — a new SQL server accepts connections from nowhere; every
  path in must be an explicit rule.
- **`0.0.0.0` is a magic value** — not "the whole internet": it means "allow
  connections from inside Azure" (other Azure services, e.g. your App Service).
  It is *not* enough to reach the DB from your laptop.
- **Rule ordering/creation** — the rules reference `server_id`, so Terraform
  creates the server first, then the rules; you can add rules without re-creating
  the server (in-place updates).
- **A single IP = start == end** — a range is `start_ip_address`…`end_ip_address`;
  keep ranges tight.
- Your public IP can change (VPN, reboot of your router) — then re-run apply with
  the new value.
