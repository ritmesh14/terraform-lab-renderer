# outputs.tf — values the module RETURNS to its caller. Callers read these as
# module.<name>.<output>. Keep outputs focused and useful for chaining.
output "vm_id"      { value = azurerm_linux_virtual_machine.web.id }
output "vm_name"    { value = azurerm_linux_virtual_machine.web.name }
output "public_ip" { value = azurerm_public_ip.web.ip_address }
output "nic_id"    { value = azurerm_network_interface.web.id }
output "vnet_id"   { value = azurerm_virtual_network.this.id }
