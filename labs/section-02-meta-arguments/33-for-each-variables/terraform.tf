# This file configures Terraform itself: the minimum Terraform version and the
# provider versions this lab is tested with. The `provider "azurerm"` block is
# required for Azure; the empty `features {}` enables the provider's default
# behaviours and is the documented minimum.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }

  }
}
# The azurerm provider is the bridge to Azure; it must be configured (features {}
# is the minimal required argument) before any azurerm_* resource can be planned.
provider "azurerm" {
  features {}
}
