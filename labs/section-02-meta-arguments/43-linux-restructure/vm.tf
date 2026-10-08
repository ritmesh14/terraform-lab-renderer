# vm.tf — the VM, using the NIC from network.tf and the key from locals.tf.
# The compute block lives in its own file so it can be swapped/scaled without
# touching networking. Note the cross-file references: var.vm_name,
# azurerm_network_interface.web, local.ssh_pubkey.
resource "azurerm_linux_virtual_machine" "web" {
  name                  = var.vm_name
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B1s"
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.web.id]
  admin_ssh_key {
    username   = "azureadmin"
    public_key = local.ssh_pubkey
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
