# Section 6 — Workflows and CI/CD

Manage multiple environments, store state remotely, version with Git, and deploy
containers (Azure Container Instances, AKS) through Azure DevOps pipelines.

## How to use these labs

Work through the labs in order — each builds on the habits of the previous one
(plan → review → apply, branching, remote state, then pipeline automation).

Prerequisites:

- **Terraform >= 1.5** (lab 126's `removed` blocks need 1.7+) — check with
  `terraform version`.
- **Azure CLI** installed and **`az login`** run — the azurerm provider uses
  your CLI session by default.
- **Git** (labs 117, 124) and, for lab 121, **kubectl** for the AKS follow-up.

The typical command flow for almost every lab:

```bash
cd <lab-folder>
terraform init       # download providers / wire up the backend (once per folder)
terraform plan       # review the diff — always
terraform apply      # create the resources
terraform output     # read declared outputs
terraform destroy    # clean up when you're done
```

Labs 115–116 add `-var-file=...` and workspace commands; lab 125 runs `terraform test`
instead of `apply`; labs 122 and 124 don't create Azure resources themselves — they
are pipeline definitions you install in a repo. Labs 119 and 123 have subfolders
(`bootstrap/` + `app/`, `base/` + `consumer/`) that run in the documented order.

## Labs 1244. [Inspecting the initial code base](114-inspect-codebase/)
115. [Deploying to multiple environments](115-multiple-environments/)
116. [Terraform workspaces — dev](116-workspaces-dev/)
117. [Using Git locally](117-git-local/)
118. [Making changes to code](118-making-changes/)
119. [Azure Storage for the state file](119-remote-state-storage/)
120. [Azure Container Instance](120-container-instance/)
121. [Azure Kubernetes Service](121-aks/)
122. [Azure DevOps release pipelines](122-devops-release-pipelines/)

## Advanced labs 1253. [`terraform_remote_state` — consume another stack](123-remote-state-consume/)
124. [GitHub Actions CI](124-github-actions/)
125. [`terraform test` framework](125-terraform-test/)
126. [`moved` and `removed` blocks](126-moved-removed/)