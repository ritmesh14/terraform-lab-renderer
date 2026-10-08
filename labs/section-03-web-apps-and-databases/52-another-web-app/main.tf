# Lab 52 (assignment) — deploy a SECOND web app reusing an existing service plan.
# We look up the plan with a `data` block (it must already exist), then create a
# new app on it. One plan can host many apps.

# Input variables with defaults — override with -var, terraform.tfvars or env
# vars. These point at the plan + resource group created in lab 51.
variable "existing_plan_name" {
  type    = string
  default = "asp-webapp"
}
variable "existing_rg_name" {
  type    = string
  default = "rg-webapp"
}
# READ the existing plan (created in lab 51). We don't manage it here.
data "azurerm_service_plan" "this" {
  name                = var.existing_plan_name
  resource_group_name = var.existing_rg_name
}

# A second app on the same plan.
# A stateful random string. Unlike md5(timestamp()) this value is SAVED in
# Terraform state, so it only changes when the resource is destroyed —
# every plan/apply is stable and nothing gets unexpectedly replaced.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_linux_web_app" "second" {
  name                = "app-second-${random_string.suffix.result}"
  location            = data.azurerm_service_plan.this.location
  resource_group_name = var.existing_rg_name
  service_plan_id     = data.azurerm_service_plan.this.id

  site_config {
    application_stack { node_version = "18-lts" }
  }
}

# Outputs print values after apply — here the new app's live URL.
output "default_hostname" { value = azurerm_linux_web_app.second.default_hostname }
