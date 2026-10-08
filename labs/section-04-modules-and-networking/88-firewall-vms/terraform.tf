# Per-lab provider setup, kept out of main.tf so the resources stay readable.

# Terraform block: which Terraform CLI and provider versions this lab requires.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}

# Provider block: configures azurerm against the subscription from `az login`.
# `features {}` is an empty settings block the azurerm provider requires.
provider "azurerm" {
  features {}
}
