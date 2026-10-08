# length() counts map entries; keys() lists the for_each keys that became subnets.
output "subnet_count" { value = length(var.subnets) }
# The list of for_each keys that became subnet names.
output "subnet_names" { value = keys(azurerm_subnet.this) }
