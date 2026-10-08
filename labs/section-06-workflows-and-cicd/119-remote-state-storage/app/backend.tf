# backend configuration is declared inline in main.tf above.
#
# Why inline? A `backend` block cannot contain expressions or variables, so its
# values are either written literally here or passed on the command line with
# `terraform init -backend-config=...` (see README / main.tf header).
#
# What each backend value means:
#   resource_group_name  — which resource group holds the state storage account
#   storage_account_name — the account (blob) that stores the state file
#   container_name       — the blob container inside it ("tfstate")
#   key                  — the state file's name INSIDE the container; unique
#                          per Terraform configuration (e.g. "app.tfstate")
