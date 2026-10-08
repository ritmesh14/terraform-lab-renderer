# Lab 124 — GitHub Actions CI (advanced)

A workflow that runs on every PR and on push to `main`:

1. `terraform fmt -check` — reject unformatted code.
2. `terraform init` + `terraform validate`.
3. `terraform plan` on PRs (posts the plan back as a comment via `hashicorp/setup-terraform`).
4. `terraform apply` automatically on push to `main`.

Secrets (`ARM_*`) are stored as GitHub repo secrets. The workflow targets one example lab;
copy and adjust `working-directory` per stack.

> Drop the generated file at the **repo root** as `.github/workflows/terraform.yml` to
> activate it.

## What the workflow does

| Step | Command | Runs on | Why |
|---|---|---|---|
| `checkout` + `setup-terraform` | — | every run | Fetch code, install Terraform 1.5.7 |
| `fmt` | `terraform fmt -check -recursive` | every run | Style gate from repo root, all stacks |
| `init` | `terraform init -input=false` | every run | Download providers; no prompts in CI |
| `validate` | `terraform validate` | every run | Catch syntax/reference errors before plan |
| `plan` | `terraform plan -input=false -no-color` | every run | The diff — the PR review artifact |
| `apply (main only)` | `terraform apply -input=false -auto-approve` | push to `main` only, via `if:` | Deploy after merge |

## What to see

- On the Actions tab: a run per PR and per push; the job's plan step shows the
  exact diff (green `+` lines) as it would apply.
- On a PR: the plan output attached to the pull request by
  `hashicorp/setup-terraform` — reviewers read infrastructure diffs without
  running anything.
- A push that changes no resources: plan reports "No changes" and apply is a
  no-op — idempotence is what makes "apply on every push" safe.
- Secrets configured under Settings → Secrets and variables → Actions: the four
  `ARM_*` values from your Azure service principal.

## Key concepts / gotchas

- **PR vs push is the review/deploy split.** PRs get fmt + validate + plan
  (read-only); only a merged push to `main` runs apply — enforced by the
  `if: github.ref == 'refs/heads/main'` condition, not by trust.
- **Secrets come from GitHub, not the file.** `ARM_CLIENT_SECRET` etc. are repo
  secrets referenced with `${{ secrets.* }}`; the YAML itself is committable and
  shows no credentials. Logs mask secret values automatically.
- **Runners are disposable.** Every job starts with an empty machine — which is
  exactly why the target stack should use remote state with locking (lab 119);
  this example targets the section-01 storage lab (local state), so swap
  `working-directory` to a remote-backend stack before trusting it with real applies.
- **`fmt -check` from the repo root** runs against all `.tf` files (note its
  separate `working-directory: .`), while init/plan/apply run inside one stack —
  a common pattern: lint repo-wide, deploy per stack.
- **`-auto-approve` belongs only in CI**, where the "review" already happened as
  the PR's plan step; never in your local workflow.
- **This is the GitHub mirror of lab 122.** Same stages, same idea — pick your
  platform, the shape (fmt → init → validate → plan → apply) stays the same.
