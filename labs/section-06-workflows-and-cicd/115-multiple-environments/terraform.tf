# The `terraform` block configures Terraform itself: the minimum CLI version
# and which providers (plugins) `terraform init` downloads.
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
# The `provider` block configures the Azure plugin. `features {}` is required
# (even empty) in azurerm 3.x. State here is local (terraform.tfstate) — remote
# backends come in lab 119.
provider "azurerm" {
  features {}
}

