# Section 5 — Operations and landing zones

Observability and governance: Azure Monitor metric alerts, Log Analytics workspaces,
RBAC role assignments, and resource locks — then a multi-resource **Application Landing
Zone** mini-project that ties them together.

## What is a "landing zone"?

A **landing zone** is the pre-built, standardized environment a team "lands" their
application into. Instead of every project inventing its own networking, logging and
permissions, the platform provides a consistent set of building blocks up front:

- **Resource groups** split by concern (network / data / security) so permissions,
  locks and cost reporting can be scoped per concern (lab 103).
- **Networking** in the classic *hub-and-spoke* shape: shared services in a hub VNet,
  workloads in isolated spoke VNets connected by peering (lab 104).
- **Central logging**: one Log Analytics workspace every resource streams diagnostics
  into, plus an archive store (labs 100, 105, 111).
- **Storage / database / Key Vault** as standardized, hardened services for the
  app tier (labs 106–108).
- **Governance**: Azure Policy assignments that refuse non-compliant resources
  (labs 109–110), RBAC role assignments instead of shared keys (labs 101, 113), and
  management locks against accidental deletion (lab 102).

In short: a landing zone is the "empty but ready" scaffolding — Terraform is how you
build and re-create that scaffolding reliably.

## How to use these labs

Prerequisites:

- **Terraform >= 1.5** (`terraform -version` to check).
- **Azure CLI** installed and signed in with `az login` — every lab uses your az cli
  credentials as its Azure identity.
- Labs that need values (an SSH key, a webhook URL, a workspace ID) ship a
  `terraform.tfvars.example`; copy it to `terraform.tfvars` in that lab's folder and
  fill it in.

Typical command flow (run inside the lab folder):

```bash
cd 98-monitor-infra            # one lab folder at a time
cp terraform.tfvars.example terraform.tfvars   # only where the lab needs it
terraform init                 # download the providers
terraform plan                 # preview what will be created
terraform apply                # create it
terraform output               # read exported values (IDs, names) other labs need
terraform destroy              # clean up when done
```

Labs 103–109 form a loose landing-zone series but each lab is self-contained (it
recreates the resources it needs); only lab 107 depends on lab 105's workspace ID,
and lab 99 on lab 98's VM id.

## Labs

98. [Azure Monitor — infrastructure](98-monitor-infra/)
99. [Metric alert via Terraform](99-metric-alert/)
100. [Log Analytics workspace](100-log-analytics/)
101. [Role assignments via Terraform](101-role-assignments/)
102. [Locking resources with Terraform](102-resource-locks/)
103. [Landing Zone — resource groups](103-landing-zone-rg/)
104. [Landing Zone — virtual network](104-landing-zone-vnet/)
105. [Landing Zone — logging](105-landing-zone-logging/)
106. [Landing Zone — storage](106-landing-zone-storage/)
107. [Landing Zone — database](107-landing-zone-database/)
108. [Landing Zone — Key Vault](108-landing-zone-keyvault/)
109. [Landing Zone — Azure Policy](109-landing-zone-policy/)

## Advanced labs 1080. [Custom policy definition + assignment](110-custom-policy-definition/)
111. [Diagnostic settings](111-diagnostic-settings/)
112. [Activity log alert + webhook](112-activity-log-alert/)
113. [Managed identity + least-privilege RBAC](113-managed-identity-rbac/)
