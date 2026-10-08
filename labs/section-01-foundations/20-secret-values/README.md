# 20 — Passing secret values

Three ways to pass a secret:

1. **tfvars** (gitignored) — simplest; fine for learning.
2. **Environment variable** — `TF_VAR_admin_password=...`.
3. **`sensitive = true` variable** — masks the value in plan/apply output.

This lab builds a small VM using all three ideas. Never commit `terraform.tfvars` for
secrets — it's listed in `.gitignore` by default.

## What it creates

| Terraform resource | Azure name | Notes |
|---|---|---|
| `azurerm_resource_group.this` | `rg-secret-foundation` | Container for the lab |
| `azurerm_virtual_network.this` | `vnet-secret` | `10.130.0.0/16` |
| `azurerm_subnet.web` | `snet-web` | `10.130.1.0/24` |
| `azurerm_network_interface.web` | `nic-secret` | Private IP only |
| `azurerm_windows_virtual_machine.web` | `vm-secret-01` | Admin password from the sensitive variable |

## Commands

Prerequisite: `az login` (or the `ARM_*` variables from lab 01). Provide the password
one of the three ways — pick **one**:

```bash
cd section-01-foundations/20-secret-values

# 1) tfvars file (copy the example, edit, don't commit)
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# 2) environment variable
export TF_VAR_admin_password="ChangeMe12345!"     # bash
$env:TF_VAR_admin_password="ChangeMe12345!"       # PowerShell

# 3) -var flag (visible in shell history — use sparingly)
terraform apply -var "admin_password=ChangeMe12345!"

terraform destroy
```

## What to see

- In the plan/apply output the password never appears — the VM shows
  `admin_password = (sensitive value)`.
- The variable has **no default**, so with no tfvars and no env var, `terraform apply`
  prompts interactively (input is hidden).
- In the Azure portal: **Resource groups** → `rg-secret-foundation` → `vm-secret-01`
  is running; log in via the NIC's private IP from inside the VNet.

## Key concepts / gotchas

- `sensitive = true` masks values **in logs only**. The password is stored in
  `terraform.tfstate` in plain text — protect the state (backends, encryption, access
  control) as carefully as the password itself.
- The three delivery channels: `TF_VAR_<name>` environment variables (good for CI),
  `-var` flags (least safe — shell history), gitignored tfvars (simplest locally).
- Marking a variable sensitive propagates: any output or attribute derived from it is
  also masked until you explicitly unsensitive it.
- `terraform.tfvars.example` is the check-in pattern: the template is committed, real
  values are not.
- For production, prefer Azure Key Vault or the azurerm provider's secret-backed
  resources instead of any local file.