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

# A registry module needs the azurerm provider configured here.
# `features {}` is an empty settings block the azurerm provider requires.
provider "azurerm" {
  features {}
}
