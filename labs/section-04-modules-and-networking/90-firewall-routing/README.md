# Lab 90 — Azure Firewall — routing traffic

A route table sends the workload subnet's outbound traffic (`0.0.0.0/0`) to the firewall
(`next_hop_type = VirtualAppliance`, next-hop IP = the firewall's private IP from lab 89). Associate the table with the workload subnet and every egress flow from that subnet
crosses the firewall first.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group` | `rg-fw-routing` | eastus |
| `azurerm_route_table` | `rt-fw` | One route: `to-firewall` |

## Commands

Prerequisite: `az login`. Needs the firewall's private IP (from lab 89's
`terraform output firewall_private_ip`):

```bash
cd labs/section-04-modules-and-networking/90-firewall-routing
cp terraform.tfvars.example terraform.tfvars   # then fill in firewall_private_ip = "10.29.0.x"
terraform init
terraform plan    # 2 resources to add
terraform apply
terraform output  # route_table_id
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-fw-routing** → **rt-fw → Routes**: one entry —
  address prefix `0.0.0.0/0`, next hop type **Virtual appliance**, next hop IP
  `10.29.0.x`.
- **Association is a separate step**: on the *workload* subnet's page
  (e.g. lab 88's `snet-workload`) → **Route table** → select **rt-fw**. Alternatively add
  an `azurerm_subnet_route_table_association` resource. Verify on
  **snet-workload → Subnet → Effective routes**: `0.0.0.0/0 → Virtual appliance`.

## Key concepts / gotchas

- **UDR = user-defined route**: custom routes that override Azure's default system
  routes for every subnet the table is associated with. `0.0.0.0/0` catches all egress.
- `next_hop_type = "VirtualAppliance"` means "a network virtual appliance at this IP" —
  here the Azure Firewall. The IP must be the firewall's **private** IP, never its
  public one.
- This config creates the route table only — the association to the subnet is what
  activates routing (portal click or `azurerm_subnet_route_table_association`).
- Once associated, Azure Firewall applies SNAT to that egress traffic (it appears to
  originate from the firewall's public IP), then its NAT/network/application rules decide
  what to allow (labs 91-92).
