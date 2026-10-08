# Lab 123 consumer — reads base/ state with data.terraform_remote_state (backend = local),
# then creates a container in the storage account base created. No resource ids copied.

# Standard terraform/provider setup; same provider versions as base/ so both
# configs read the same state attributes the same way.
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

# Read outputs from the base stack's local state. A `data` source is READ-ONLY:
# this config never creates, changes or destroys base's resources — it just
# loads base's state file and exposes `base.outputs.*` here.
data "terraform_remote_state" "base" {
  backend = "local"
  config = {
    # `path.module` is the folder this file lives in; the relative path points
    # at the sibling stack's state file. In production this would instead be
    # backend = "azurerm" with the same storage/container/key as lab 119.
    path = "${path.module}/../base/terraform.tfstate"
  }
}

# A container inside the storage account that BASE created. Note the reference
# chain: Terraform only knows the account via the remote-state output, so the
# consumer can be owned and applied by a different team with zero shared code.
resource "azurerm_storage_container" "from_base" {
  name                  = "consumed"
  storage_account_name  = data.terraform_remote_state.base.outputs.storage_account_name
  container_access_type = "private"
}

# Echo what was read from the other stack — proof the state connection works.
output "consumed_in" { value = data.terraform_remote_state.base.outputs.storage_account_name }
