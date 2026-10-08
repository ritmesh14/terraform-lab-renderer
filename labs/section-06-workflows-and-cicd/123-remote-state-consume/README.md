# Lab 123 — `terraform_remote_state` — consume another stack's outputs (advanced)

Two configs that don't know each other's code, only each other's **state**. `base/`
creates a storage account and outputs its name. `consumer/` reads `base`'s state with
`data "terraform_remote_state"` and creates a container inside that storage account.
This is the glue between independently-owned Terraform stacks: outputs are the
contract, remote state is the delivery mechanism.

## What it creates / does

| Config | Terraform resource | Azure name | Notes |
|---|---|---|---|
| `base/` | `random_string.suffix` | — | 6 chars for a unique account name |
| `base/` | `azurerm_resource_group.this` | `rg-remote-base` | Holds the shared storage |
| `base/` | `azurerm_storage_account.this` | `stremote<suffix>` | Exports `storage_account_name` / `resource_group_name` outputs |
| `consumer/` | `data.terraform_remote_state.base` | (read-only) | Loads `../base/terraform.tfstate`, no Azure resources |
| `consumer/` | `azurerm_storage_container.from_base` | Container `consumed` in base's account | Referenced purely via `base.outputs.*` |

## Commands

```bash
# Prerequisite: az login
cd 123-remote-state-consume/base
terraform init && terraform apply      # produces base/terraform.tfstate

cd ../consumer
terraform init && terraform apply      # reads base's outputs from that file
terraform output consumed_in           # the account name read from base's state

# cleanup: destroy consumer FIRST (it created something inside base's account)
cd ../consumer && terraform destroy
cd ../base && terraform destroy
```

## What to see

- `consumer/` has no knowledge of the storage account's name anywhere in its
  code — run `terraform output consumed_in` and it still resolves correctly.
- In the portal: container `consumed` inside the `stremote...` account that only
  `base/` ever declared.
- `terraform state list` in each folder: base owns two resources, consumer one —
  ownership is cleanly split even though one sits inside the other.

## Key concepts / gotchas

- **Outputs are the interface.** Only what `base` exports is consumable; anything
  else stays private to its state. Design outputs deliberately — they are your
  cross-team API.
- **`terraform_remote_state` is read-only.** The consumer can reference base's
  values but cannot change them; base's code and state remain the single owner.
- **Order matters.** Base must be applied before consumer (the state file must
  exist), and destroyed *after* consumer, or consumer's target disappears
  underneath it. Real repos encode this in pipeline order.
- **This lab uses the `local` backend for the data source** (a file path) for
  simplicity. For teams, base should use a remote backend (lab 119) — then the
  consumer points at the same storage/container/key instead of a file path.
- **No resource ids copied by hand.** The moment you paste an id or name between
  stacks, you've created hidden coupling; outputs + remote state keep the
  dependency visible in code.
