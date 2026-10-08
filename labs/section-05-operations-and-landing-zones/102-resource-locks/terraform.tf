# Terraform + provider setup, shared by the labs in this section.
#   required_version  >= 1.5.0 : minimum Terraform CLI version.
#   azurerm ~> 3.70            : the Azure provider; "~>" means any 3.x >= 3.70,
#                                so a provider 4.0 can never change behavior under us.
#   random ~> 3.6              : used by labs that need random_string suffixes.
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
# Provider block: authenticates Terraform to Azure using your `az login` credentials.
# features {} turns on the default (empty) behavior block — it is required by the provider.
provider "azurerm" {
  features {}
}