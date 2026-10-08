output "vnet_id"    { value = azurerm_virtual_network.this.id }
output "subnet_ids" { value = azurerm_subnet.this[*].id }
output "subnet_names" { value = azurerm_subnet.this[*].name }
