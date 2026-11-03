# Lab 51 — Azure Web App

Section 3 · Web apps and databases — Lab 51.

## S001 — TITLE

Welcome back. Sections one and two gave you the foundations and then made your configurations dynamic. This is Lab fifty one, the first lab of Section three — and it changes the game. Instead of building a virtual machine, you hand your code to Azure App Service, a managed platform that runs the app for you: no V M to build, no operating system to patch, nothing to babysit. Let's deploy a web app.

## S002 — CONCEPT: What you'll learn

- App Service — managed web apps, no VM to build or patch
- Service plan versus web app — the compute versus the code
- A stateful random suffix — stable app name across applies
- The default hostname output — your live site URL

Here's what you'll learn in this lesson. One: what App Service is — Azure's managed platform for web apps, and why the virtual machine disappears. Two: the split between a service plan, which is the compute your app runs on, and the web app, which is the code itself. Three: how a stateful random string keeps the app's name stable across every apply. Four: how the default hostname output hands you the live site URL the moment apply finishes.

## S003 — CONCEPT: Where this lab fits

- Section 1 — foundations
- Section 2 — meta arguments
- Section 3 — managed platforms: App Service, SQL, slots, autoscale

Where does this fit? Section one built the foundations — resource groups, networking, even a full virtual machine. Section two made configurations dynamic with meta arguments. Section three moves up the abstraction ladder: from owning machines to using managed platforms. Everything in this section — deployment slots, SQL databases, autoscaling — reuses the two core resources you create in this very first lab: a service plan and a web app.

## S004 — CONCEPT: Where to find this lab

You'll find this lab in the course GitHub repository, linked in the description, under Section three, Web apps and databases — folder fifty one, web app. Three files. Main dot T F holds the four resources. Terraform dot T F pins the providers. And the README has the exact commands to run.

## S005 — DIAGRAM: How the pieces connect

[Diagram: lab51-deploy-order.svg — rg-webapp → asp-webapp (B1, Linux) → app-webapp-<suffix>; random_string.suffix → app (unique name)]

Here's how the pieces connect. Everything starts with the resource group — it's the container the whole lab deploys into. The service plan defines the app's pricing tier and operating system. It points at the group's name and location, so it waits for the group. The web app runs on that plan — the service plan id is the dependency that connects them. And a random string feeds the app's name, so every deployment of this lab gets a unique web app. Keep this picture in mind — the next scenes walk the exact Terraform blocks that build it.

## S006 — CODE

```hcl
# This file pins the tooling: which Terraform CLI version works, and which
# providers (from where, at which version) the azurerm resources come from.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The azurerm provider is the "driver" Terraform uses to talk to Microsoft
# Azure. `features {}` is required (an empty block is fine) and turns on
# default behaviour.
provider "azurerm" {
  features {}
}
```

First, the tooling pins. The terraform block declares the providers this lab uses: azurerm to talk to Azure, and random for the random string you'll meet in a moment. The version ranges mean every machine that builds this lab resolves the same provider code. Below, the provider block turns on azurerm's default behaviour — the features block is required by the provider, even when you don't customize anything inside it.

## S007 — CODE

```hcl
# locals = named values computed once. Keeping the resource-group name here
# means one place to change it.
locals { rg = "rg-webapp" }

# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}
```

Now main dot T F. Locals are named values computed once — here the resource group name lives in one place, so changing it later is a one-line edit. Then the random string. Length six, lowercase letters and digits only — upper and special are switched off, so the suffix is a clean, web-safe fragment for a domain name. And the key idea: random string is a resource. Its value is saved in Terraform state, so it only changes when the resource is destroyed. Every plan and apply reuses the same suffix — the app's name stays stable.

## S008 — CODE

```hcl
# A resource group is Azure's folder/container: every resource lives in one,
# and deleting the group deletes everything in it.
resource "azurerm_resource_group" "this" {
  name     = local.rg
  location = "eastus"
}
```

The resource group — you've created one in every lab since section one. The name comes from the local you just saw, and the location is East US. It's the folder the service plan and the web app will live in, and deleting the group still deletes everything inside it.

## S009 — CODE

```hcl
# The Service Plan = the compute tier. sku_name "B1" = small shared Linux.
# os_type must match the web app (Linux here).
resource "azurerm_service_plan" "this" {
  name                = "asp-webapp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}
```

The service plan is the compute tier. O S type Linux — it must match the web app you put on it. And the SKU, B one, is the Basic tier: a small, shared Linux instance. The plan answers one question: how much machine does my app get? Every web app sits on exactly one service plan, and the plan's tier controls scaling and features — keep that in mind for deployment slots later in this section.

## S010 — CODE

```hcl
# A Linux Web App runs your code. Names are globally unique (web app DNS).
resource "azurerm_linux_web_app" "this" {
  name                = "app-webapp-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id

  site_config {
    application_stack {
      node_version = "18-lts" # the runtime/language stack
    }
  }
}

# Outputs print values after apply — here the live site URL, e.g. https://app-webapp-ab12cd.azurewebsites.net
output "default_hostname" { value = azurerm_linux_web_app.this.default_hostname }
```

The web app itself. Its name appends the random suffix — because web app names are globally unique across all of Azure: the domain is the app's name dot azurewebsites dot net, and no two apps can share one. The important line is service plan underscore id — the hard dependency that says: this app runs on that plan. Inside site config, the application stack sets the runtime: node, version eighteen L T S. And at the bottom, the output prints the default hostname — the live URL of your site once apply finishes.

## S011 — MANIM

Watch the deployment order unfold. Terraform starts with the resource group — nothing else can exist without it. Next, the service plan: it reads the group's name and location, so it waits for the group. Then the web app — service plan id is the hard dependency that makes it wait for the plan. And the suffix? It depends on nothing, so Terraform can create it any time — it only feeds the app's name.

## S012 — CONCEPT: How Terraform orders the work

- References become dependency edges
- Graph walks top to bottom on create
- Destroy walks the same graph in reverse

How did Terraform know to build the group first? It read the references. The plan reads the group's name, so it waits for the group. The app reads the plan's id, so it waits for the plan. Terraform turns those references into a dependency graph and walks it top to bottom — you never write the create order by hand. And when you destroy, it walks the same graph in reverse: the app goes first, the group goes last.

## S013 — TERMINAL

Here's the plan — terraform plan, an illustrative view. Four resources to add, nothing to change, nothing to destroy: the random string, the resource group, the service plan, and the Linux web app — exactly the inventory you just read. And because the suffix is stateful, after apply its value is saved in state — every later plan keeps the same app name.

## S014 — CONCEPT: Common pitfalls

- B1 is not free — destroy when done
- Web app names are globally unique — that's the suffix's job
- os_type must match — Linux app needs a Linux plan
- No timestamp tricks — random_string is the stateful way

Here are the pitfalls in this lab. One: B one is not free. The Basic tier bills by the hour — destroy the lab when you're done. Two: web app names are global. The suffix exists because app name dot azurewebsites dot net must be unique across all of Azure. Three: O S type must match — a Linux web app needs a Linux service plan, so keep them in sync. Four: don't fake randomness with a timestamp. An M D five of timestamp trick regenerates on every run and destroys and recreates your app each time — random string is a stateful resource for exactly this reason.

## S015 — RECAP

- App Service = managed web hosting, no VM
- Service plan is the compute; web app is the code
- service_plan_id binds app to plan
- random_string suffix is stateful — stable names
- default_hostname output = the live site URL

Quick recap — five things. One: App Service is Azure's managed platform for web apps: no virtual machine, no patching. Two: the service plan is the compute tier; the web app is your code running on it. Three: service plan id is the reference that binds the app to the plan. Four: the random suffix is a stateful resource — stable across applies. Five: the default hostname output hands you the live site URL.

## S016 — NEXT

Now that we understand how this Terraform configuration works, in the next part of this video, we'll move to a real-world demo and deploy it in Microsoft Azure.

## S017 — CONCEPT: Thanks for watching

Thanks for watching. If this helped, the full lab — along with every lab in this course — is in the GitHub repository linked in the description. See you in the next one.
