# Lab 70 — App Service source control (deploy from Git).
# Wire the web app to a Git repo so Azure builds & deploys on every push.
# For a PUBLIC repo a placeholder token is accepted; a private repo needs a PAT.
# This pins the tooling: Terraform CLI version + the provider that talks to Azure.
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

# The repo Azure deploys from (a public sample by default) and the branch to track.
variable "repo_url" {
  type    = string
  default = "https://github.com/Azure-Samples/nodejs-docs-hello-world"
}
variable "branch" {
  type    = string
  default = "main"
}
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# A resource group is Azure's folder: everything this lab creates lives here.
resource "azurerm_resource_group" "this" {
  name     = "rg-appsourcecontrol"
  location = "eastus"
}

# The Service Plan = the compute tier the web app runs on (B1 Basic, Linux).
resource "azurerm_service_plan" "this" {
  name                = "asp-appsourcecontrol"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# The Linux Web App that Git will deploy into.
resource "azurerm_linux_web_app" "this" {
  name                = "app-sourcecontrol-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  site_config {
    application_stack { node_version = "18-lts" }
  }
}

# source_control: Azure pulls from the repo on push (CI = false → Azure builds it).
# In azurerm 3.x the resource is azurerm_app_service_source_control (it works
# for Linux web apps too); no credential block — public repos need no token.
resource "azurerm_app_service_source_control" "this" {
  app_id                 = azurerm_linux_web_app.this.id
  repo_url               = var.repo_url
  branch                 = var.branch
  use_manual_integration = false
}

# Outputs print values after apply — the app's live URL.
output "hostname" { value = azurerm_linux_web_app.this.default_hostname }
