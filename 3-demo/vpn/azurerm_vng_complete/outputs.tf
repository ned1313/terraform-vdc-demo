output "vng_pip_name" {
  value = "${azurerm_public_ip.vng-pip.name}"
}

output "vng_id" {
  value = "${azurerm_virtual_network_gateway.vng.id}"
}
