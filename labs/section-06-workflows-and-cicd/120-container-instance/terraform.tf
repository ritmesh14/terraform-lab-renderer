# The `terraform` block pins the CLI version and lists the azurerm provider
# that `terraform init` downloads. (Shared settings live in terraform.tf so
# main.tf can focus on the container resources.)
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}
# The `provider` block configures the Azure plugin. `features {}` must be
# present (it can stay empty) in azurerm 3.x.
provider "azurerm" {
  features {}
}
