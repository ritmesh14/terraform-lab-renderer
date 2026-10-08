# Lab 125 — `terraform test` (advanced)

Terraform's built-in test framework (`.tftest.hcl`) runs assertions against `plan` and
`apply` without external tools. This lab ships a tiny storage-account config and a test
that asserts the plan contains exactly one storage account with the expected tier.
Think of it as unit tests for infrastructure code: they run in CI (labs 122/11) before
any plan ever reaches a human reviewer.

## What it creates / does

| Piece | Name | Notes |
|---|---|---|
| `main.tf` | `random_string.suffix`, `azurerm_resource_group.this` (`rg-tftest`), `azurerm_storage_account.this` (`sttftest<suffix>`) | The small config under test; tier comes from `var.tier` |
| `variables.tf` | `variable "tier"` | Defaults to `"Standard"`; the thing a test could override |
| `tests/main.tftest.hcl` | 2 `run` blocks, each `command = plan` | Assertions on `plan.planned_values` — no Azure resources created |
| `output.storage_name` | — | Exposed for apply-based tests |

## Commands

```bash
# Prerequisite: az login (needed for provider auth during plan)
cd 125-terraform-test
terraform init
terraform test                 # runs both run blocks; PASS/FAIL per test
terraform test -verbose        # show the plan each run block executed
```

Try breaking a test to see it fail: temporarily change the `account_tier`
assertion's expected value (or the variable default) and rerun — `terraform test`
reports the failing `run` block, the assertion's `error_message`, and exits
non-zero, which is exactly how a CI pipeline would treat it.

## What to see

- Terminal output like:
  ```
  run "plan_has_one_storage_account": PASS
  run "storage_uses_standard_tier": PASS
  ```
- No new resources in the portal: `command = plan` tests never create anything.
- With `-verbose`: the full plan per run block — handy to see exactly what the
  assertions inspected.

## Key concepts / gotchas

- **`command = plan` vs `command = apply`.** Plan tests are fast, free and
  inspect `plan.planned_values.*`; apply tests actually create (and then
  destroy) real resources and can assert on real values — use plan by default,
  apply only when the behavior only exists after creation.
- **Assertions are just expressions.** `condition` must be true; anything else
  fails with your `error_message`. Keep messages human — they're what the CI
  log shows.
- **Planned values, not live Azure.** These tests validate the *configuration*:
  resource count, attribute values, variable handling. They do not prove the
  resource works after creation — that's what `apply`-mode tests or integration
  checks are for.
- **The variable makes the test meaningful.** Because `account_tier` is
  `var.tier`, the tier test is checking real behavior (the config honors its
  inputs), not a hard-coded constant.
- **Runs are isolated.** Each `run` block executes its own plan, so tests don't
  depend on each other's ordering; variables can be overridden per run block.
- **Wire it into CI.** `terraform test` belongs in the same slot as
  `terraform validate` in labs 122/11 — cheap checks that block a bad merge.
