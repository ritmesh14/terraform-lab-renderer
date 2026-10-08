# Output: the SSH target — unknown during plan, assigned by Azure at apply.
output "public_ip" { value = azurerm_public_ip.web.ip_address }
