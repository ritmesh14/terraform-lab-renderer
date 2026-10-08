# 24 — `templatefile()` (advanced)

`templatefile(path, vars)` renders a local file as a Terraform template, substituting the
`vars` map. Use it to keep large cloud-init / scripts out of `.tf` and parameterise them.

This lab renders `cloud-init.tpl` with a hostname and a list of packages, then passes
the result (base64) to a Linux VM's `custom_data`.

Addressing: VNet `172.17.0.0/20`, subnet `172.17.0.0/26`.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-templatefile` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-templatefile` | `172.17.0.0/20` |
| `azurerm_subnet.web` | `snet-web` | `172.17.0.0/26` |
| `azurerm_network_interface.web` | `nic-templatefile` | Private IP only |
| `azurerm_linux_virtual_machine.web` | `vm-templatefile` | Ubuntu 22.04 LTS, `Standard_B1s`, SSH key auth |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01) and an SSH key.

```bash
cd section-01-foundations/24-templatefile
cp terraform.tfvars.example terraform.tfvars   # paste your public key
terraform init
terraform plan
terraform apply
terraform output rendered_preview              # see the substituted template
terraform destroy
```

Generate a key if you don't have one: `ssh-keygen -t ed25519`.

## What to see

- `terraform output rendered_preview` shows the template with `hostname` substituted and
  the package list expanded (first 120 chars only).
- In the Azure portal: **Resource groups** → `rg-templatefile` → `vm-templatefile` →
  **Overview**. On a jumpbox in the VNet you could browse to the VM's private IP and see
  the nginx page the `runcmd` commands wrote: `host: web-templatefile built by
  templatefile()`.
- Under the VM → **Extensions + applications**, no agent needed — cloud-init ran on
  first boot via `custom_data`.

## Key concepts / gotchas

- `templatefile(path, vars)` takes an absolute or module-relative path (hence
  `path.module`) and a map of variables; the template uses `${var}` for substitution and
  `%{ for p in packages ~} ... %{ endfor ~}` for loops and conditionals.
- `custom_data` **must be base64-encoded** (`base64encode(...)`); Azure decodes it and
  cloud-init consumes it on first boot only.
- `custom_data` changes force VM replacement (Azure can't update it in place) — treat
  template edits as reboots of the VM.
- The template lives outside `.tf` (it is not parsed by Terraform beyond the markers),
  keeping big scripts versioned and editable on their own.
- `admin_ssh_key` is a `sensitive` variable — same masking rules as lab 20; and note the
  template file's own comment trick: raw `${` in a comment would be parsed as a
  directive, so it spells the markers out in words.