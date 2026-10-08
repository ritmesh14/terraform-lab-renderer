# Lab 126 — `moved` and `removed` blocks (advanced refactoring)

Two refactoring primitives:

- `moved {}` — change a resource's address **without** recreating it (see also lab 23 in
  section 1).
- `removed {}` — drop a resource from Terraform's management **without destroying** it in
  Azure (it stays, now unmanaged). Useful when you want Terraform to stop owning
  something but keep it running.

This lab creates a storage account and demonstrates both blocks. `removed` here targets
a placeholder address so the first apply is a no-op; the README walks through the real
two-step refactor workflow.

## What it creates / does

| Terraform resource | Azure name | Notes |
|---|---|---|
| `random_string.suffix` | (not an Azure resource) | 6 random chars for a unique account name |
| `azurerm_resource_group.this` | `rg-moved-removed` | Container for the stack |
| `azurerm_storage_account.this` | `stmovedrm<suffix>` | Standard LRS; the "new" address after the move |
| `moved` block | (no Azure effect) | Relabels state `azurerm_storage_account.legacy` → `.this` |
| `removed` block | (no Azure effect) | Forgets `azurerm_storage_account.orphan` from state |
| `output.storage_name` | — | The account name after the refactor |

## Commands

```bash
# Prerequisite: az login   (and Terraform >= 1.7 for the `removed` block)
cd 126-moved-removed
terraform init
terraform plan      # moved block is a no-op if .legacy was never in state
terraform apply
terraform output storage_name
terraform destroy   # only destroys what Terraform still owns
```

The full refactor workflow this lab models (try it in a scratch copy):

```bash
# 1. Old code still calls the resource azurerm_storage_account.legacy -> apply
# 2. Rename .legacy to .this in code AND add:
#      moved { from = azurerm_storage_account.legacy  to = azurerm_storage_account.this }
#    -> terraform plan shows "will move ... no create/destroy"
# 3. To stop managing something instead: delete its resource block and add:
#      removed { from = azurerm_storage_account.orphan }
#    -> apply forgets it in state, leaves it running in Azure
```

## What to see

- A plan with the `moved` block (and `.legacy` in state) shows:
  `# azurerm_storage_account.legacy will be moved to azurerm_storage_account.this`
  — with zero `+` or `-` resources.
- A plan with the `removed` block on a resource that **is** in state shows
  `# azurerm_storage_account.orphan has been removed from Terraform's
  management` and no destroy line.
- In the Azure portal after `removed`: the account still exists under
  `rg-moved-removed` — Terraform simply no longer tracks it.

## Key concepts / gotchas

- **`moved` = rename, `destroy` avoided.** Without the block, renaming a
  resource in code means Terraform sees "old address gone, new address appears"
  and plans a destroy + create — which for a storage account means data loss.
- **`removed` = forget, not delete.** The Azure resource keeps running and
  billing; it just leaves Terraform's state. This is the escape hatch for
  "Terraform built it, but ops now owns it."
- **`removed` is strict about state.** If the address was never in state,
  `terraform plan` fails with "Removing resource block that is not present in
  state" — so this lab's placeholder block needs a two-step demo (create the
  orphan first) before it will plan cleanly.
- **Both blocks are code artifacts, then deleted.** Once the refactor has been
  applied by every environment, remove the `moved` block (it's inert but noise);
  keep a `removed` block only as long as every environment's state still
  contains the orphan.
- **Version check.** `removed` blocks need Terraform 1.7+ (the config here only
  declares `>= 1.5`); `moved` blocks have been available since 1.1.
