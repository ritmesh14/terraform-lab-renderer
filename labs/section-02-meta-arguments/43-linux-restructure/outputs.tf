# Outputs: printed after apply (also with `terraform output`). vm_id is the full
# Azure resource ID — handy for feeding other systems or tests.
output "vm_name" { value = azurerm_linux_virtual_machine.web.name }
output "vm_id" { value = azurerm_linux_virtual_machine.web.id }
