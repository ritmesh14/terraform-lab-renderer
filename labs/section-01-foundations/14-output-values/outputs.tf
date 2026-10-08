# outputs.tf — `output` blocks expose values after apply and to other configs.
# `sensitive = true` masks the value in plan/apply logs (it still prints on demand
# via `terraform output <name>`). Use it for keys/passwords.
output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "Name of the storage account."
}

# The blob endpoint URL, handy to paste into a browser or a later lab.
output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

# The account's primary access key — a real secret, hence the masking below.
output "primary_access_key" {
  value     = azurerm_storage_account.this.primary_access_key
  sensitive = true # won't appear in plain text in the terminal output
}

