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

# The `provider {}` block configures the Azure plugin. `features {}` is required by
# azurerm even when empty. Credentials are NOT put here on purpose — the provider
# reads them automatically from the ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID /
# ARM_SUBSCRIPTION_ID environment variables you exported in the shell.
provider "azurerm" {
  features {}
}

# A `data` block READS information that already exists; it does not create anything.
# Here we read the subscription Terraform authenticated against, to prove the
# credentials work and to surface its id/name as outputs.
data "azurerm_subscription" "current" {}

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
