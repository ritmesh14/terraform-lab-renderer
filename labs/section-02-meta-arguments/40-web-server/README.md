# Lab 40 — Web server via Terraform

Deploy a Linux VM and install nginx using the `custom_data` (cloud-init) mechanism — the
Terraform-native, idempotent alternative to a one-off provisioner. The VM gets a static
public IP and an NSG rule for HTTP.

> Gotcha: the NSG is created in this lab but never **associated** with the subnet (there
> is no association resource), so the HTTP rule is not actually enforced — see
> "Key concepts" below.

## What it creates

| Terraform resource                 | Azure name                     | Notes                                       |
| ---------------------------------- | ------------------------------ | ------------------------------------------- |
| `azurerm_resource_group.this`      | Resource group `rg-webserver`  | 1                                           |
| `azurerm_virtual_network.this`     | VNet `vnet-webserver`          | 1, `10.220.0.0/16`                          |
| `azurerm_subnet.web`               | Subnet `snet-web`              | 1, `10.220.1.0/24`                          |
| `azurerm_network_security_group.web` | NSG `nsg-webserver`          | 1, Allow TCP 80 rule (**not associated**)   |
| `azurerm_public_ip.web`            | Public IP `pip-webserver`      | 1, Static / Standard                        |
| `azurerm_network_interface.web`    | NIC `nic-webserver`            | 1, attaches the public IP                   |
| `azurerm_linux_virtual_machine.web`| VM `vm-webserver`              | 1, Ubuntu 22.04 + cloud-init nginx          |

## Commands

```bash
cd 40-web-server
terraform init
terraform plan
terraform apply -var=admin_ssh_key="ssh-rsa AAAA... your@email"
terraform output public_ip   # then open http://<that IP>
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-webserver`: VM `vm-webserver` with public IP `pip-webserver`.
- VM `vm-webserver` → **Overview** → note the FQDN/IP, then (if you add the NSG
  association described below, so port 80 is open) browse to `http://<public ip>` —
  nginx serves the "Hello from Terraform-built web server" page that `custom_data`
  wrote at first boot.
- NSG `nsg-webserver` → **Inbound security rules**: the `Allow-HTTP` (TCP 80) rule
  exists, but the **Subnets** tab shows no association in this lab.

## Key concepts / gotchas

- `custom_data = base64encode(local.cloud_init)` runs **once at first boot** — it is
  the Terraform-native, idempotent way to bootstrap a VM, preferred over provisioners.
- `<<-EOT ... EOT` is a heredoc: multi-line text with the common indent stripped. The
  content is cloud-init YAML (`#cloud-config`, packages, `runcmd`).
- The public IP is attached in the NIC's `ip_configuration`
  (`public_ip_address_id`), not on the VM block.
- If you change anything inside the heredoc, Terraform sees `custom_data` changed and
  will **replace** the VM (custom_data cannot be updated in place).
- Suspected gap (left as-is on purpose): the NSG has no
  `azurerm_subnet_network_security_group_association`, so the HTTP rule is not applied
  to the subnet — add one if the page is not reachable.
