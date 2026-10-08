# Lab 01 — Authentication with a Service Principal

**Episode:** section-01-foundations/01-authentication-app-object
**Lesson label:** Azure Foundations — Lab 01
**Public lab:** https://github.com/RIT-MESH/Terraform-Azure-Labs-and-Case_Studies/tree/master/labs/section-01-foundations/01-authentication-app-object
**Scope:** `main.tf` only (per source-manifest). No other lab's resources appear.

---

## S001 — TITLE

Welcome to the course. In this very first lesson, we start at step zero of
every Terraform project: authenticating Terraform to Microsoft Azure. Not
with an interactive login, but with a service principal, the same way a CI
pipeline would. By the end, Terraform will prove it can sign in, by reading
your Azure subscription and printing it back to you.

## S002 — CONCEPT: What you'll learn

- What a service principal is, and why pipelines can't log in interactively
- How Terraform picks up credentials from ARM_* environment variables
- A first look at data blocks and output blocks

Here's what we'll cover. What a service principal is, and why pipelines
can't just log in interactively. How Terraform picks up credentials from
environment variables, so no secret ever lands in your code. And we'll meet
two foundational building blocks: a data block that reads from Azure, and
outputs that surface the results.

## S003 — CONCEPT: Where this lab fits

This is lab one of the Foundations section. Everything that follows —
resource groups, networks, virtual machines — builds on this. Because
before Terraform can create a single resource, it has to prove to Azure who
it is. Get authentication right once, and every later lab just works,
including in automated pipelines.

## S004 — CONCEPT: Interactive login vs service principal

- `az login` — works for a human at a keyboard
- Service principal — an identity for applications and pipelines
- Contributor role on the subscription

So far you may have used az login to authenticate interactively. That works
for a human at a keyboard, but a build agent has nobody to type a password.
A service principal is an identity for applications and pipelines. We give
it a client ID, a client secret, and permission — in our case the
Contributor role on the subscription. Terraform then signs in as that
identity, with no human involved.

## S005 — CONCEPT: Where to find this lab

GitHub breadcrumb (never local paths):

```
RIT-MESH / Terraform-Azure-Labs-and-Case_Studies
  └── labs
      └── section-01-foundations
          └── 01-authentication-app-object
              ├── README.md
              └── main.tf
```

You can find this lab in the course GitHub repository under Section 1,
Foundations. The direct link is in the video description. The lab is tiny
on purpose: one file, main dot T F, and a README. That's all we need to
prove authentication works.

## S006 — CODE: main.tf — the terraform block (lines 1–18)

```hcl
# ---------------------------------------------------------------------------
# Lab 01 — Authentication with an App Registration (service principal)
# This lab creates NO Azure resources. It only proves Terraform can sign in to
# Azure using credentials supplied via ARM_* environment variables.
# ---------------------------------------------------------------------------

# The `terraform {}` block configures Terraform itself: which version to use and
# which providers (plugins) to download. `azurerm` is the official Azure provider.
terraform {
  required_version = ">= 1.5.0" # fail early on Terraform versions older than 1.5

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # the registry namespace/name of the provider
      version = "~> 3.70"           # allow patch updates within the 3.70 line
    }
  }
}
```

Let's open main dot T F. The first block configures Terraform itself. The
terraform block sets the minimum version, one point five or newer, so old
versions fail early with a clear message instead of a confusing error. And
required providers pins the Azure R M provider from the official HashiCorp
registry, allowing patch updates within the three point seventy line.
Terraform downloads this provider automatically when we run init.

## S007 — CODE: main.tf — the provider block (lines 20–26)

```hcl
# The `provider {}` block configures the Azure plugin. `features {}` is required by
# azurerm even when empty. Credentials are NOT put here on purpose — the provider
# reads them automatically from the ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID /
# ARM_SUBSCRIPTION_ID environment variables you exported in the shell.
provider "azurerm" {
  features {}
}
```

Next, the provider block configures the Azure plugin. The features block is
required by Azure R M, even when it's empty. Notice what is not here: no
client ID, no secret, nothing sensitive. Credentials are deliberately kept
out of the code. The provider reads them from the environment instead,
which is exactly what we'll set up next.

## S008 — DIAGRAM: Credentials flow from the environment

ARM_* environment variables → azurerm provider → Azure AD sign-in →
Azure subscription.

We export four environment variables: ARM subscription ID, ARM client ID,
ARM client secret, and ARM tenant ID. The Azure R M provider picks these up
automatically at run time. Think of it as the provider checking the
environment before it talks to Azure. Credentials live in your shell or
pipeline secrets, never in dot T F files, and never in version control.

## S009 — CODE: main.tf — the data block (lines 28–31)

```hcl
# A `data` block READS information that already exists; it does not create anything.
# Here we read the subscription Terraform authenticated against, to prove the
# credentials work and to surface its id/name as outputs.
data "azurerm_subscription" "current" {}
```

Now the interesting part. This data block reads the subscription Terraform
authenticated against. A data block reads something that already exists;
it creates nothing. Compare that with a resource block, which creates and
manages infrastructure. Since this lab only needs to prove our credentials
work, reading is exactly what we want.

## S010 — CODE: main.tf — the outputs (lines 33–43)

```hcl
# `output` blocks print values after `terraform apply` and make them available to
# other configurations. These confirm which subscription we are targeting.
output "subscription_id" {
  value       = data.azurerm_subscription.current.subscription_id
  description = "The subscription Terraform authenticated against."
}

# Prints the subscription's friendly display name.
output "display_name" {
  value = data.azurerm_subscription.current.display_name
}
```

Finally, two outputs. Outputs print values after apply, and make them
available to other tools. The first returns the subscription ID from the
data block; the second returns its friendly display name. If Terraform can
read these, authentication works, and we can see the proof right in the
terminal.

## S011 — DIAGRAM: The whole picture

Terraform config → azurerm provider → Azure Resource Manager → subscription
→ outputs.

Here's the whole picture. Your credentials flow from the environment into
the Azure R M provider. The provider signs in to Azure Resource Manager as
the service principal. The data block reads your subscription, and the
outputs hand its ID and name back to you. Four small blocks, one clear
proof of identity.

## S012 — TERMINAL: terraform init / plan / apply

Illustrative terminal output (clearly labeled as illustrative; the
real-world demo episode shows actual captured output).

Time to run it. Terraform init downloads the Azure R M provider. Terraform
plan shows there is nothing to create, only a value to read. Then
terraform apply does that read, and prints both outputs: the subscription
ID, and the display name. What you see on screen is an illustrative view of
what that looks like.

## S013 — CONCEPT: Common pitfall

- Auth error on plan/apply → check the four ARM_* variables
- Most common causes: missing, misspelled, or expired client secret

One common pitfall. If plan or apply fails with an authorization error,
it's almost always the environment variables: missing, misspelled, or an
expired client secret. The fix is the same every time: check the four ARM
variables, and if the secret expired, create a new one. Terraform's error
message will point you straight at this.

## S014 — RECAP

- Service principal = identity for pipelines, created once with the Azure CLI
- Credentials come from the four ARM_* environment variables, never from code
- terraform block pins versions; provider block stays credential-free
- data blocks read; resource blocks create
- Outputs printing = authentication proven

Quick recap. A service principal is an identity for pipelines, created
once with the Azure CLI. Terraform reads credentials from the four ARM
environment variables, never from code. The terraform block pins versions
and providers; the provider block stays credential-free. A data block reads
existing Azure objects without creating anything, and outputs surface the
results. If the outputs print, authentication works.

## S015 — NEXT

Now that we understand how this Terraform configuration works, in the next
part of this video, we'll move to a real-world demo and deploy it in
Microsoft Azure.

## S016 — CONCEPT: Outro

Thanks for watching. If this helped, the full lab, along with every lab in
this course, is in the GitHub repository linked below. See you in the next
lesson.