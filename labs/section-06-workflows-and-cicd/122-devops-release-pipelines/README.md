# Lab 122 — Azure DevOps release pipelines

This lab is a **pipeline definition**, not Terraform resources. Below is an example Azure
DevOps YAML pipeline that validates, plans, and applies the section-01 storage lab.
It is the CI/CD endgame of this section: instead of a human running `plan`/`apply`
from a laptop (labs 117–118), the pipeline runs them on every push to `main`, with the
plan artifact reviewed between the two.

Save it as `azure-pipelines.yml` at the repo root, create a service connection named
`azure-arm` (an ARM service principal), and run the pipeline.

## Variables / secret handling

Store `ARM_CLIENT_SECRET` as a pipeline secret variable. The `terraform plan` step
publishes a plan artifact; the `apply` stage waits on approval, then applies.

## What the pipeline does

| Piece | YAML | What it means |
|---|---|---|
| Trigger | `trigger: branches: include: [main]` | Run on every push to `main` |
| Agent | `pool: vmImage: ubuntu-latest` | Microsoft-hosted build VM |
| Variables | `terraformVersion`, `workingDirectory` | Pinned CLI; which stack to deploy |
| Stage 1 — Plan | `terraform init / validate / plan -out=tfplan` | Read-only; publishes `tfplan` as an artifact |
| Stage 2 — Apply | `download: tfplan` then `terraform apply tfplan` | Applies the exact reviewed plan, gated by `dependsOn: Plan` |
| Auth | `ARM_*` env vars | Pipeline (secret) variables feeding Terraform's Azure auth |

## What to see

- In Azure DevOps → Pipelines: the two-stage run diagram — `Plan` first, then
  `Apply` waiting on `dependsOn: Plan` (and, if configured, on your approval).
- The `tfplan` artifact under the run's "Published artifacts".
- A second run with no code change: plan says "No changes" — the pipeline is a
  no-op because the code matches the state.
- Stage approvals: Pipelines → Environments / stage settings → add an approver
  so `Apply` needs a human click.

## Key concepts / gotchas

- **Plan artifact, not a fresh plan at apply time.** The Apply stage applies the
  *downloaded* plan file. Recomputing a plan later could apply something nobody
  reviewed if the code or Azure changed between stages.
- **`-auto-approve` is safe here** because the plan was already reviewed and
  approved as part of the stage; in CI there's no terminal to type "yes" into.
- **Secrets live in pipeline variables**, never in the YAML. `ARM_CLIENT_SECRET`
  must be a secret variable — masked in logs — and the repo stays clean.
- **Two stages = two gates.** Plan is safe to run anywhere and anytime; Apply is
  where money and downtime happen, so it is the stage you gate with approvals
  and branch policies.
- **State backend matters in CI too.** The pipeline's agent is disposable — the
  lab it points at should use a remote backend (lab 119), otherwise each run's
  agent starts with an empty local state. (This example targets the section-01
  storage lab, which still uses local state — swap `workingDirectory` to a
  remote-backend stack for a real setup.)
- **Note the auth style here:** this YAML authenticates via `ARM_*` pipeline
  variables rather than the `azure-arm` service connection mentioned above —
  the service connection is only needed if you switch to AzureCLI/service
  connection tasks instead of plain env vars.
