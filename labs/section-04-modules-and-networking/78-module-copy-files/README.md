# Lab 78 — Modules — copying files to the server

Use `custom_data` (cloud-init) to write files at boot — the recommended, idempotent
alternative to scp + provisioner. This lab deploys the `vm-stack` module and feeds it a
cloud-init snippet via the `custom_data` input. At first boot the VM writes `/etc/motd`
and logs its boot time to `/var/log/boot-tf.log`.

Module: `labs/modules/vm-stack` (same as lab 77, plus the `custom_data` input).

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| Same stack as lab 77 | `rg-modcopy` … `vm-modcopy` | All names from prefix `modcopy` |
| `custom_data` on the VM | (VM property "Custom data") | `base64encode(local.cloud_init)` |

## Commands

Prerequisite: `az login`. This lab needs your SSH public key:

```bash
cd labs/section-04-modules-and-networking/78-module-copy-files
cp terraform.tfvars.example terraform.tfvars   # then paste your key inside
terraform init
terraform plan    # 8 resources to add
terraform apply
terraform output  # public_ip
terraform destroy
```

## What to see in the Azure portal

- Resource group **rg-modcopy** → **vm-modvm**.
- Verify the files landed: `ssh azureadmin@<public_ip>` (key from your tfvars), then
  `cat /etc/motd` (should show "Provisioned by the section-04 vm-stack module") and
  `cat /var/log/boot-tf.log`.
- **vm-modvm → Support + troubleshooting → Boot diagnostics** also shows the cloud-init
  log (`/var/lib/waagent/custom-data` is where Azure keeps the payload).

## Key concepts / gotchas

- **custom_data must be base64-encoded** — the caller does `base64encode(local.cloud_init)`
  before passing it into the module; the module just forwards it to the VM.
- Cloud-init runs **once, on first boot**. To re-run it you must re-provision the VM
  (`terraform taint`/`-replace`), which is exactly why file copies belong in the image
  and not in a provisioner that fights with state.
- `<<-EOT` is the indented heredoc — it strips the leading indentation so the YAML stays
  readable inside HCL.
- The locals block holds the cloud-init template: named, reusable, computed once per run.
