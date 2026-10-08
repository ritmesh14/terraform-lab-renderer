# outputs.tf — values returned to the caller / printed after apply.
# Outputs can also live in their own file — same merge rule as everything else.
output "vnet_id" { value = azurerm_virtual_network.this.id }
# The VNet's human-readable name.
output "vnet_name" { value = azurerm_virtual_network.this.name }
