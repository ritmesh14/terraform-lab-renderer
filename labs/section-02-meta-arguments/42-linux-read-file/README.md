# Lab 42 — Linux machine — read a local file

`file()` and `filebase64()` read a file from the lab folder at plan/apply time. Here we
read a public SSH key from `id_rsa.pub` and feed it to the VM. (Create the file or
replace with your own key.)

Also introduces `templatefile()` as the next step for injecting a templated script.

## What it creates

| Terraform resource                  | Azure name                         | Notes                              |
| ----------------------------------- | ---------------------------------- | ---------------------------------- |
| `azurerm_resource_group.this`       | Resource group `rg-linux-readfile` | 1                                  |
| `azurerm_virtual_network.this`      | VNet `vnet-linux-readfile`         | 1, `10.230.0.0/16`                 |
| `azurerm_subnet.web`                | Subnet `snet-web`                  | 1, `10.230.1.0/24`                 |
| `azurerm_network_interface.web`     | NIC `nic-readfile`                 | 1, dynamic private IP              |
| `azurerm_linux_virtual_machine.web` | VM `vm-readfile`                   | 1, Ubuntu 22.04, SSH key from file |

## Commands

```bash
cd 42-linux-read-file
# optional: drop your own public key next to main.tf
ssh-keygen -t rsa -b 4096 -f id_rsa -N "" -C ""   # creates id_rsa + id_rsa.pub
terraform init
terraform plan
terraform apply
terraform destroy
```

## What to see in the Azure portal

- Resource group `rg-linux-readfile` → VM `vm-readfile` → **Connect → SSH** (or the VM's
  public IP if you add one): the VM accepts the key that was read from `id_rsa.pub`
  (or the built-in placeholder if the file was absent).

## Key concepts / gotchas

- `file("id_rsa.pub")` reads the file **at plan time**, relative to the module's
  working directory — the content becomes part of the config.
- `fileexists(...) ? ... : ...` is a ternary: guard the read so a missing file falls
  back to a placeholder instead of failing the whole plan.
- Files read with `file()` are inputs, not state: deleting the file later makes
  Terraform want to replace the VM's `admin_ssh_key` (key change = update).
- `filebase64()` is the same read as base64 (useful for `custom_data`); `templatefile()`
  goes one step further and interpolates variables into the file's `${...}` slots.
- Never commit real private keys into a lab folder — only `.pub` public keys are read
  here.
