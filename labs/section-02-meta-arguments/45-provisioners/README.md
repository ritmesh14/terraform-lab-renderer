# Lab 45 — Provisioners

Provisioners run scripts **at create/destroy time**. They are a **last resort**: they
are not idempotent, not visible in `plan`, and fail the run if they error. Prefer
`custom_data`/cloud-init or a configuration tool (Ansible, Chef, etc.).

This lab demonstrates a `remote-exec` provisioner over SSH that prints the OS release —
only to show the mechanics. Notice `connection {}` and the `self` reference.

## What it creates

| Terraform resource                  | Azure name                      | Notes                                    |
| ----------------------------------- | ------------------------------- | ---------------------------------------- |
| `azurerm_resource_group.this`       | Resource group `rg-provisioner` | 1                                        |
| `azurerm_virtual_network.this`      | VNet `vnet-provisioner`         | 1, `10.251.0.0/16`                       |
| `azurerm_subnet.web`                | Subnet `snet-web`               | 1, `10.251.1.0/24`                       |
| `azurerm_network_security_group.web`| NSG `nsg-provisioner`           | 1, Allow TCP 22 (**not associated**)     |
| `azurerm_public_ip.web`             | Public IP `pip-provisioner`     | 1, Static / Standard                     |
| `azurerm_network_interface.web`     | NIC `nic-provisioner`           | 1, binds subnet + public IP              |
| `azurerm_linux_virtual_machine.web` | VM `vm-provisioner`             | 1, plus `remote-exec` provisioner        |

## Commands

```bash
cd 45-provisioners
terraform init
terraform plan
terraform apply -var=admin_public_key="ssh-rsa AAAA... your@email" -var=admin_private_key="$(cat ~/.ssh/id_rsa)"
terraform output public_ip
terraform destroy
```

Watch the apply output: after the VM is created, Terraform SSHes in and streams the
`remote-exec` commands.

## What to see in the Azure portal

- Resource group `rg-provisioner`: VM `vm-provisioner`, NIC `nic-provisioner`, static
  public IP `pip-provisioner`.
- The provisioner's effects are on **your terminal**, not in the portal — the VM has no
  visible change beyond what the commands did (here: just output).

## Key concepts / gotchas

- `provisioner "remote-exec"` runs once, at **create** time, over a `connection` block
  (SSH here; `type = "winrm"` for Windows). `inline` is a list of shell commands.
- `self.public_ip_address` refers to the resource the provisioner lives on — you can't
  use the regular `azurerm_public_ip.web.ip_address` inside it (it's not known during
  provisioning), but `self` is.
- The `private_key = var.admin_private_key` in `connection` is the key Terraform
  logs in with — it must be the private half of the keypair whose **public** half
  (`admin_public_key`) the VM trusts. A public key is not a private key, so this lab
  keeps them as two separate sensitive variables (never paste a `.pub` into
  `admin_private_key` — the SSH handshake would fail).
- Provisioners are invisible to `terraform plan` and a failing script marks the
  resource "tainted" (destroyed and recreated on the next apply).
- Suspected gap (left as-is on purpose): the NSG has no subnet association, so inbound
  SSH from the internet relies on Azure's default rules; if `remote-exec` times out,
  that is the first thing to check.
- Use a `file` provisioner to copy local files up, `local-exec` to run something on
  YOUR machine (e.g. `echo` into a local inventory file).
