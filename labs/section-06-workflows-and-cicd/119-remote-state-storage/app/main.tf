# Lab 119 Part B — a config that USES the remote backend.
# The backend block (azurerm) is declared inline; fill its values via
#   terraform init -backend-config=resource_group_name=... -backend-config=storage_account_name=... ...
# Now state lives in Azure Storage (shared + locked), not on a laptop.

# The `terraform` block now includes a `backend "azurerm"` — state leaves your
# laptop and lives as a blob in Azure Storage instead of terraform.tfstate.
# Backend values that are still placeholders below get overridden at init time
# with -backend-config=... flags (see README); the "key" is the blob's file
# name inside the container and must be unique per Terraform config.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }
  }

  backend "azurerm" {
    # Fill via `terraform init -backend-config=...` (see README).
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate<suffix>"
    container_name       = "tfstate"
    key                  = "app.tfstate"
  }
}

# The `provider` block configures the Azure plugin. `features {}` must be
# present (it can stay empty) in azurerm 3.x.
provider "azurerm" {
  features {}
}

# A trivial resource so you can watch the remote backend in action: apply, then
# look for app.tfstate as a blob in the Part A container. Note there is no
# local terraform.tfstate anymore after a remote-backend init.
resource "azurerm_resource_group" "app" {
  name     = "rg-remote-state-app"
  location = "eastus"
}

output "rg_name" { value = azurerm_resource_group.app.name }
