# Lab 117 — Using Git on our local machine

Version your Terraform. This lab has no Terraform of its own — it's the Git workflow
that sits underneath every CI/CD pipeline in this section: Terraform code lives in a
repository, environments/changes are branches, and a merge to `main` is what a
pipeline later reacts to. Everything here runs against whatever directory you copied
earlier labs into (a `.gitignore` keeps state and secrets out).

## What it creates / does

| Step | Command | What it means |
|---|---|---|
| Create a repo | `git init` | Start tracking this folder's history in `.git/` |
| Stage + commit | `git add .`, `git commit -m "..."` | Save a checkpoint of the Terraform code |
| Branch | `git branch feature/networking`, `git switch feature/networking` | Experiment without touching `main` |
| Merge | `git switch main`, `git merge feature/networking` | Land the reviewed change |
| Release | `git tag v1.0` | Mark a point you could roll back to |
| Inspect | `git log --oneline`, `git diff` | See history / what changed before committing |

## Commands

```bash
git init
git add .
git commit -m "initial Terraform"
git branch feature/networking
git switch feature/networking
# ... make changes ...
git switch main
git merge feature/networking
git tag v1.0
git log --oneline
```

Useful companions while working with Terraform:

```bash
git status          # which .tf files changed
git diff            # the code diff you are about to commit
git log --oneline   # history of infrastructure changes
```

## What to see

- `.gitignore` containing `terraform.tfstate*`, `.terraform/`, and secret
  `*.tfvars` files — `git status` should never offer to commit them.
- Each `git log --oneline` line is one auditable infrastructure change, which is
  what a CI pipeline (labs 122, 124) will later build/apply automatically.

## Key concepts / gotchas

- **Never commit `terraform.tfstate`** — it can contain secrets (passwords,
  connection strings) and every teammate having a different copy of state is
  how conflicts start. Remote state (lab 119) is the real fix.
- **Never commit secret tfvars** — use `terraform.tfvars.example` templates or
  environment variables instead.
- **Review every PR for `plan` output.** In IaC, the code diff and the
  infrastructure diff should match; pasting the `terraform plan` into the PR is
  the standard review artifact.
- **Tag releases so you can roll back** — `git revert` the code, re-plan, and
  Terraform diffs you back to the tagged state.
- **Branches are your staging ground.** A feature branch's plan shows what the
  change will do; merging is the point at which it becomes "the infrastructure
  code of record".
